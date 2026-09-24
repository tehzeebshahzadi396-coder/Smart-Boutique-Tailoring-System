import 'package:flutter_test/flutter_test.dart';

import 'package:smart_boutique/services/fabric_calculator_service.dart';

void main() {
  late FabricCalculatorService service;

  setUp(() {
    service = FabricCalculatorService();
  });

  test('Anarkali Flare Kurti uses height * 1.5 plus width * 0.5', () {
    final double meters = service.calculateFabric(
      designType: 'Anarkali Flare Kurti',
      height: 2,
      width: 1,
    );
    expect(meters, 3.50);
    expect(service.toYards(meters), closeTo(3.50 * 1.09361, 0.0001));
  });

  test('Layered Frock uses height * 1.8 plus width * 0.75', () {
    final double meters = service.calculateFabric(
      designType: 'Layered Frock',
      height: 2,
      width: 1,
    );
    expect(meters, 4.35);
  });

  test('invalid dimensions are rejected', () {
    expect(
      () => service.calculateFabric(
        designType: 'Basic Shirt',
        height: 0,
        width: 1,
      ),
      throwsA(isA<FabricCalculatorException>()),
    );
    expect(
      () => service.calculateFabric(
        designType: 'Basic Shirt',
        height: 1.5,
        width: -10,
      ),
      throwsA(isA<FabricCalculatorException>()),
    );
  });
}
