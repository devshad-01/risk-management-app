import 'package:dio/dio.dart';
import 'package:riskflow_fx/features/risk/models/price_quote.dart';
import 'package:riskflow_fx/features/risk/services/price_service.dart';

class YahooFinancePriceService implements PriceService {
  YahooFinancePriceService({Dio? client}) : _client = client ?? Dio();

  final Dio _client;

  static const _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  @override
  Future<PriceQuote> getLatestPrice(String symbol) async {
    final yahooSymbol = _toYahooSymbol(symbol);
    final response = await _client.get<dynamic>(
      '$_baseUrl/$yahooSymbol',
      queryParameters: {
        'interval': '1m',
        'range': '1d',
      },
      options: Options(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid Yahoo response');
    }

    final chart = data['chart'];
    if (chart is! Map<String, dynamic>) {
      throw Exception('Invalid Yahoo chart payload');
    }

    final error = chart['error'];
    if (error != null) {
      throw Exception('Yahoo error for $yahooSymbol');
    }

    final results = chart['result'];
    if (results is! List || results.isEmpty) {
      throw Exception('No Yahoo result for $yahooSymbol');
    }

    final result = results.first;
    if (result is! Map<String, dynamic>) {
      throw Exception('Invalid Yahoo result format');
    }

    final meta = result['meta'] as Map<String, dynamic>?;
    final marketPrice = _asDouble(meta?['regularMarketPrice']);

    if (marketPrice != null && marketPrice > 0) {
      return PriceQuote(
        price: marketPrice,
        source: PriceSource.live,
        timestamp: DateTime.now(),
      );
    }

    final indicators = result['indicators'] as Map<String, dynamic>?;
    final quotes = indicators?['quote'] as List<dynamic>?;
    final firstQuote = quotes != null && quotes.isNotEmpty ? quotes.first as Map<String, dynamic>? : null;
    final closes = firstQuote?['close'] as List<dynamic>?;

    if (closes != null && closes.isNotEmpty) {
      for (var index = closes.length - 1; index >= 0; index--) {
        final price = _asDouble(closes[index]);
        if (price != null && price > 0) {
          return PriceQuote(
            price: price,
            source: PriceSource.live,
            timestamp: DateTime.now(),
          );
        }
      }
    }

    throw Exception('No valid Yahoo price found for $yahooSymbol');
  }

  String _toYahooSymbol(String symbol) {
    final upper = symbol.trim().toUpperCase();
    const mapping = <String, String>{
      'EURUSD': 'EURUSD=X',
      'GBPUSD': 'GBPUSD=X',
      'AUDUSD': 'AUDUSD=X',
      'NZDUSD': 'NZDUSD=X',
      'USDJPY': 'USDJPY=X',
      'EURJPY': 'EURJPY=X',
      'GBPJPY': 'GBPJPY=X',
      'AUDJPY': 'AUDJPY=X',
      'USDCAD': 'USDCAD=X',
      'USDCHF': 'USDCHF=X',
      'EURGBP': 'EURGBP=X',
      'XAUUSD': 'GC=F',
      'XAGUSD': 'SI=F',
      'US30': '^DJI',
      'US100': '^NDX',
      'US500': '^GSPC',
      'GER40': '^GDAXI',
      'UK100': '^FTSE',
      'BTCUSD': 'BTC-USD',
      'ETHUSD': 'ETH-USD',
    };

    return mapping[upper] ?? upper;
  }

  double? _asDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
