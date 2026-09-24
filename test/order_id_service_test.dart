import 'package:flutter_test/flutter_test.dart';

import 'package:smart_boutique/services/order_id_service.dart';

void main() {
  final OrderIdService service = OrderIdService();

  test('first order ID uses the current year and sequence 0001', () {
    final String id = service.generateNext(
      existingIds: const [],
      now: DateTime(2026, 9, 24),
    );
    expect(id, 'ORD-2026-0001');
    expect(service.isValid(id), isTrue);
  });

  test('order IDs increment uniquely for the same year', () {
    final String first = service.generateNext(
      existingIds: const [],
      now: DateTime(2026),
    );
    final String second = service.generateNext(
      existingIds: [first],
      now: DateTime(2026),
    );
    expect(first, isNot(second));
    expect(second, 'ORD-2026-0002');
  });

  test('sequence follows the highest existing ID', () {
    final String next = service.generateNext(
      existingIds: const ['ORD-2026-0012', 'ORD-2025-0099'],
      now: DateTime(2026, 1, 1),
    );
    expect(next, 'ORD-2026-0013');
  });
}
