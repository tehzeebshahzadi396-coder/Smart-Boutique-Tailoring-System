class Measurement {
  final double teera;
  final double chest;
  final double waist;
  final double armhole;
  final double length;

  const Measurement({
    required this.teera,
    required this.chest,
    required this.waist,
    required this.armhole,
    required this.length,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      teera: (json['teera'] as num).toDouble(),
      chest: (json['chest'] as num).toDouble(),
      waist: (json['waist'] as num).toDouble(),
      armhole: (json['armhole'] as num).toDouble(),
      length: (json['length'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teera': teera,
      'chest': chest,
      'waist': waist,
      'armhole': armhole,
      'length': length,
    };
  }

  Measurement copyWith({
    double? teera,
    double? chest,
    double? waist,
    double? armhole,
    double? length,
  }) {
    return Measurement(
      teera: teera ?? this.teera,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      armhole: armhole ?? this.armhole,
      length: length ?? this.length,
    );
  }
}
