class Instrument {
  const Instrument({
    required this.symbol,
    required this.pipSize,
    required this.pipValuePerStandardLot,
    required this.minLot,
    required this.lotStep,
    required this.fallbackPrice,
    required this.pricePrecision,
    this.label,
    this.category = 'forex',
  });

  final String symbol;
  final double pipSize;
  final double pipValuePerStandardLot;
  final double minLot;
  final double lotStep;
  final double fallbackPrice;
  final int pricePrecision;
  final String? label;
  final String category;

  String get displayLabel => label ?? symbol;
}
