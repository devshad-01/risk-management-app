import 'dart:convert';

import 'package:riskflow_fx/features/risk/models/instrument.dart';
import 'package:riskflow_fx/features/risk/models/price_quote.dart';
import 'package:riskflow_fx/features/risk/services/local_storage_service.dart';
import 'package:riskflow_fx/features/risk/services/price_service.dart';

class CachedPriceService implements PriceService {
  CachedPriceService({
    required PriceService primary,
    required LocalStorageService storageService,
    required List<Instrument> instruments,
  })  : _primary = primary,
        _storageService = storageService,
        _instruments = {for (final item in instruments) item.symbol: item};

  final PriceService _primary;
  final LocalStorageService _storageService;
  final Map<String, Instrument> _instruments;

  static const _cachePrefix = 'price_cache_';

  @override
  Future<PriceQuote> getLatestPrice(String symbol) async {
    try {
      final liveQuote = await _primary.getLatestPrice(symbol);
      await _persist(symbol, liveQuote.price, liveQuote.timestamp);
      return liveQuote;
    } catch (_) {
      final cached = _readCache(symbol);
      if (cached != null) {
        return cached;
      }

      final instrument = _instruments[symbol];
      if (instrument == null) {
        throw Exception('No live price or fallback configured for $symbol');
      }

      return PriceQuote(
        price: instrument.fallbackPrice,
        source: PriceSource.fallback,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<void> _persist(String symbol, double price, DateTime timestamp) {
    final payload = jsonEncode({
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    });
    return _storageService.writeString('$_cachePrefix$symbol', payload);
  }

  PriceQuote? _readCache(String symbol) {
    final raw = _storageService.readString('$_cachePrefix$symbol');
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final price = (decoded['price'] as num).toDouble();
      final timestamp = DateTime.parse(decoded['timestamp'] as String);
      return PriceQuote(
        price: price,
        source: PriceSource.cached,
        timestamp: timestamp,
      );
    } catch (_) {
      return null;
    }
  }
}