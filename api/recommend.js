// api/recommend.js
// Vercel Node.js serverless function.
// GEMINI_API_KEY lives exclusively in Vercel server-side environment variables.
// It is never passed to the Flutter build and never appears in client JS.

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// Simple in-memory rate limiter: max 10 requests per IP per 60 seconds.
const rateLimitMap = new Map(); // ip -> { count, resetAt }
const RATE_LIMIT = 10;
const RATE_WINDOW_MS = 60_000;

function checkRateLimit(ip) {
  const now = Date.now();
  let entry = rateLimitMap.get(ip);
  if (!entry || now > entry.resetAt) {
    entry = { count: 0, resetAt: now + RATE_WINDOW_MS };
    rateLimitMap.set(ip, entry);
  }
  entry.count += 1;
  return entry.count <= RATE_LIMIT;
}

// Periodically clean up expired entries to avoid memory growth.
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of rateLimitMap.entries()) {
    if (now > entry.resetAt) rateLimitMap.delete(ip);
  }
}, RATE_WINDOW_MS);

export default async function handler(req, res) {
  // ── CORS ──────────────────────────────────────────────────────────────────
  // Allow the Flutter web app (same origin on Vercel) and local dev server.
  const allowedOrigins = [
    process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : '',
    'http://localhost',
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:8080',
  ].filter(Boolean);

  const origin = req.headers['origin'] || '';
  const isAllowed =
    allowedOrigins.some((o) => origin.startsWith(o)) ||
    // In production, same-origin requests from the Flutter app have no Origin header.
    !origin;

  if (isAllowed) {
    res.setHeader('Access-Control-Allow-Origin', origin || '*');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  // ── Method guard ──────────────────────────────────────────────────────────
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  // ── Rate limiting ─────────────────────────────────────────────────────────
  const clientIp =
    req.headers['x-forwarded-for']?.split(',')[0].trim() ||
    req.socket?.remoteAddress ||
    'unknown';
  if (!checkRateLimit(clientIp)) {
    return res
      .status(429)
      .json({ error: 'Too many requests. Please try again in a minute.' });
  }

  // ── API key check ─────────────────────────────────────────────────────────
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('[recommend] GEMINI_API_KEY is not set in environment.');
    return res.status(503).json({
      error:
        'AI service is not configured. Please contact the administrator.',
    });
  }

  // ── Input validation ──────────────────────────────────────────────────────
  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    return res.status(400).json({ error: 'Invalid JSON body.' });
  }

  const prompt = body?.prompt;
  if (typeof prompt !== 'string' || prompt.trim().length === 0) {
    return res
      .status(400)
      .json({ error: 'Missing or empty "prompt" field in request body.' });
  }

  const trimmedPrompt = prompt.trim();
  if (trimmedPrompt.length > 2000) {
    return res
      .status(400)
      .json({ error: 'Prompt exceeds maximum length of 2000 characters.' });
  }

  // ── Build Gemini request ──────────────────────────────────────────────────
  const systemPrefix =
    'As an expert boutique fashion designer, provide styling and tailoring advice for: ';
  const fullPrompt = systemPrefix + trimmedPrompt;

  const geminiPayload = {
    contents: [{ parts: [{ text: fullPrompt }] }],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 1024,
    },
    safetySettings: [
      { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
      { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
    ],
  };

  // ── Call Gemini REST API with timeout ─────────────────────────────────────
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 28_000); // 28 s (Vercel limit is 30 s)

  try {
    const geminiRes = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(geminiPayload),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!geminiRes.ok) {
      const errBody = await geminiRes.text();
      console.error(`[recommend] Gemini API error ${geminiRes.status}: ${errBody}`);

      if (geminiRes.status === 400) {
        return res.status(502).json({ error: 'The request was rejected by the AI service.' });
      }
      if (geminiRes.status === 401 || geminiRes.status === 403) {
        return res.status(502).json({ error: 'AI service authentication failed. Check GEMINI_API_KEY in Vercel.' });
      }
      if (geminiRes.status === 429) {
        return res.status(502).json({ error: 'AI service quota exceeded. Please try again later.' });
      }
      return res.status(502).json({ error: `AI service returned an error (${geminiRes.status}).` });
    }

    const data = await geminiRes.json();
    const text =
      data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ||
      'No recommendation generated.';

    return res.status(200).json({ recommendation: text });
  } catch (err) {
    clearTimeout(timeout);
    if (err.name === 'AbortError') {
      console.error('[recommend] Gemini request timed out.');
      return res.status(504).json({ error: 'AI service request timed out. Please try again.' });
    }
    console.error('[recommend] Unexpected error:', err);
    return res.status(500).json({ error: 'An unexpected error occurred.' });
  }
}
