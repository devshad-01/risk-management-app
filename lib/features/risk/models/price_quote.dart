enum PriceSource {
  live,
  cached,
  fallback,
}

class PriceQuote {
  const PriceQuote({
    required this.price,
    required this.source,
    required this.timestamp,
  });

  final double price;
  final PriceSource source;
  final DateTime timestamp;
}