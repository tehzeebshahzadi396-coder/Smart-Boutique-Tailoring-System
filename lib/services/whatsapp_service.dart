import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'WhatsApp open nahi ho saka: $url';
    }
  }
}