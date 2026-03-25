import 'package:riskflow_fx/features/risk/models/price_quote.dart';

abstract class PriceService {
  Future<PriceQuote> getLatestPrice(String symbol);
}
