import 'package:dio/dio.dart';
import 'package:riskflow_fx/features/risk/models/price_quote.dart';
import 'package:riskflow_fx/features/risk/services/price_service.dart';

class TwelveDataPriceService implements PriceService {
  TwelveDataPriceService({
    Dio? client,
    String? apiKey,
    String? Function()? apiKeyResolver,
  })  : _client = client ?? Dio(),
        _apiKey = apiKey,
        _apiKeyResolver = apiKeyResolver;

  final Dio _client;
  final String? _apiKey;
  final String? Function()? _apiKeyResolver;

  static const _quoteUrl = 'https://api.twelvedata.com/quote';
  static const _priceUrl = 'https://api.twelvedata.com/price';
  static const _envApiKey = String.fromEnvironment('TWELVEDATA_API_KEY');

  @override
  Future<PriceQuote> getLatestPrice(String symbol) async {
    final apiKey = (_apiKeyResolver?.call() ?? _apiKey ?? _envApiKey).trim();
    if (apiKey.isEmpty) {
      throw Exception('Missing TWELVEDATA_API_KEY. Use --dart-define.');
    }

    final apiSymbol = _normalizeSymbol(symbol);

    final priceFromFastEndpoint = await _fetchFromPriceEndpoint(
      apiSymbol: apiSymbol,
      apiKey: apiKey,
    );

    if (priceFromFastEndpoint != null) {
      return PriceQuote(
        price: priceFromFastEndpoint,
        source: PriceSource.live,
        timestamp: DateTime.now(),
      );
    }

    final response = await _client.get<dynamic>(
      _quoteUrl,
      queryParameters: {
        'symbol': apiSymbol,
        'apikey': apiKey,
      },
      options: Options(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid quote response');
    }

    if (data['status'] == 'error') {
      final message = data['message']?.toString() ?? 'Price API error';
      throw Exception(message);
    }

    final directPrice = _asDouble(data['price']) ?? _asDouble(data['close']) ?? _asDouble(data['last']);
    final ask = _asDouble(data['ask']);
    final bid = _asDouble(data['bid']);
    final midpoint = ask != null && bid != null ? (ask + bid) / 2 : null;
    final price = directPrice ?? midpoint;

    if (price == null || price <= 0) {
      throw Exception('No valid live price found for $apiSymbol');
    }

    final timestampRaw = data['last_quote_at'] ?? data['timestamp'];
    final timestamp = timestampRaw is num
        ? DateTime.fromMillisecondsSinceEpoch(timestampRaw.toInt() * 1000)
        : DateTime.now();

    return PriceQuote(
      price: price,
      source: PriceSource.live,
      timestamp: timestamp,
    );
  }

  Future<double?> _fetchFromPriceEndpoint({
    required String apiSymbol,
    required String apiKey,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        _priceUrl,
        queryParameters: {
          'symbol': apiSymbol,
          'apikey': apiKey,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return null;
      }
      if (data['status'] == 'error') {
        return null;
      }
      final price = _asDouble(data['price']);
      if (price == null || price <= 0) {
        return null;
      }
      return price;
    } catch (_) {
      return null;
    }
  }

  String _normalizeSymbol(String symbol) {
    if (symbol.contains('/')) {
      return symbol;
    }

    final upper = symbol.trim().toUpperCase();
    final sixLetters = RegExp(r'^[A-Z]{6}$');
    if (sixLetters.hasMatch(upper)) {
      return '${upper.substring(0, 3)}/${upper.substring(3, 6)}';
    }

    return upper;
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
