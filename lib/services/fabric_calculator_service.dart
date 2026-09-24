import '../utils/app_constants.dart';

class FabricCalculatorException implements Exception {
  const FabricCalculatorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Estimated fabric calculations for common boutique garments.
/// Results are academic/demo estimates, not cutting-room guarantees.
class FabricCalculatorService {
  double calculateFabric({
    required String designType,
    required double height,
    required double width,
  }) {
    if (height <= 0 || width <= 0) {
      throw const FabricCalculatorException(
        'Height and width must be positive numbers.',
      );
    }

    final double meters = switch (designType) {
      'Anarkali Flare Kurti' => _anarkali(height, width),
      'Layered Frock' => _layeredFrock(height, width),
      'Straight Kurti' => _straightKurti(height, width),
      'A-Line Frock' => _aLineFrock(height, width),
      'Basic Shirt' => _basicShirt(height, width),
      _ => throw FabricCalculatorException('Unknown garment design: $designType'),
    };

    return _normalize(meters);
  }

  double toYards(double meters) => meters * AppConstants.metersToYards;

  /// Anarkali Flare Kurti: extra flare from width.
  double _anarkali(double height, double width) {
    final double baseFabric = height * 1.5;
    final double additionalFlareAllowance = width * 0.5;
    return baseFabric + additionalFlareAllowance;
  }

  /// Layered Frock: extra fabric for stacked layers.
  double _layeredFrock(double height, double width) {
    final double baseFabric = height * 1.8;
    final double layerAllowance = width * 0.75;
    return baseFabric + layerAllowance;
  }

  double _straightKurti(double height, double width) {
    return height * 1.2 + width * 0.30;
  }

  double _aLineFrock(double height, double width) {
    return height * 1.6 + width * 0.45;
  }

  double _basicShirt(double height, double width) {
    return height * 1.1 + width * 0.25;
  }

  /// Rounds up to the next 0.05 m so shop staff can buy practical lengths.
  double _normalize(double meters) {
    final double roundedUp = (meters * 20).ceil() / 20;
    return double.parse(roundedUp.toStringAsFixed(2));
  }
}
