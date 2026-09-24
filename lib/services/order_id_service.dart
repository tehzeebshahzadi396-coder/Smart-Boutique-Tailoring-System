class OrderIdService {
  static final RegExp _pattern = RegExp(r'^ORD-(\d{4})-(\d{4})$');

  /// Generates `ORD-YYYY-0001` style IDs. Sequence continues from existing IDs
  /// for the current year so values stay unique after app restarts.
  String generateNext({
    required List<String> existingIds,
    DateTime? now,
  }) {
    final int year = (now ?? DateTime.now()).year;
    int maxSequence = 0;

    for (final String id in existingIds) {
      final Match? match = _pattern.firstMatch(id);
      if (match == null) {
        continue;
      }
      final int idYear = int.parse(match.group(1)!);
      final int sequence = int.parse(match.group(2)!);
      if (idYear == year && sequence > maxSequence) {
        maxSequence = sequence;
      }
    }

    final String padded = (maxSequence + 1).toString().padLeft(4, '0');
    return 'ORD-$year-$padded';
  }

  bool isValid(String id) => _pattern.hasMatch(id);
}
