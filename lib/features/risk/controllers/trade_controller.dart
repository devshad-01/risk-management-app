import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riskflow_fx/core/constants/instruments.dart';
import 'package:riskflow_fx/features/risk/domain/risk_calculator.dart';
import 'package:riskflow_fx/features/risk/models/instrument.dart';
import 'package:riskflow_fx/features/risk/models/price_quote.dart';
import 'package:riskflow_fx/features/risk/models/risk_result.dart';
import 'package:riskflow_fx/features/risk/models/trade_preset.dart';
import 'package:riskflow_fx/features/risk/services/local_storage_service.dart';
import 'package:riskflow_fx/features/risk/services/price_service.dart';

enum ExitMode { simple, partial }
enum PriceProvider { twelveData, yahooFinance }

class TradeController extends GetxController {
  TradeController({
    required PriceService priceService,
    required PriceService yahooPriceService,
    required LocalStorageService storageService,
  })  : _priceService = priceService,
        _yahooPriceService = yahooPriceService,
        _storageService = storageService;

  final PriceService _priceService;
  final PriceService _yahooPriceService;
  final LocalStorageService _storageService;
  final RiskCalculator _calculator = const RiskCalculator();

  static const _presetKey = 'trade_presets';
  static const _draftKey = 'trade_draft_v1';
  static const _favoritesKey = 'favorite_symbols_v1';
  static const _apiKeyStorageKey = 'twelvedata_api_key';
  static const _priceProviderKey = 'price_provider_v1';

  final balanceCtrl = TextEditingController(text: '5000');
  final riskPercentCtrl = TextEditingController(text: '1.0');
  final entryCtrl = TextEditingController();
  final stopCtrl = TextEditingController();
  final rrTargetCtrl = TextEditingController(text: '2.0');
  final tp1RCtrl = TextEditingController(text: '1.0');
  final tp2RCtrl = TextEditingController(text: '2.0');
  final tp1CloseCtrl = TextEditingController(text: '50');
  final apiKeyCtrl = TextEditingController();

  final selectedInstrument = supportedInstruments.first.obs;
  final favoriteSymbols = <String>[].obs;
  final instrumentQuery = ''.obs;
  final selectedInstrumentTab = 'all'.obs;
  final selectedExitMode = ExitMode.simple.obs;
  final selectedPriceProvider = PriceProvider.twelveData.obs;
  final useBreakEven = false.obs;
  final currentPrice = RxnDouble();
  final currentPriceSource = Rxn<PriceSource>();
  final lastQuoteAt = Rxn<DateTime>();
  final isFetchingPrice = false.obs;

  final lastError = ''.obs;
  final lastRiskResult = Rxn<RiskResult>();
  final partialPlanResult = Rxn<PartialPlanResult>();
  final simpleTpPrice = RxnDouble();
  final tp1Price = RxnDouble();
  final tp2Price = RxnDouble();
  final presets = <TradePreset>[].obs;
  final appVersionLabel = 'v1.0.0 (1)'.obs;
  Timer? _draftSaveDebounce;
  final _textControllers = <TextEditingController>[];
  final _workers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    _loadPresets();
    _loadDraft();
    _bindDraftPersistence();
    _loadAppVersion();
  }

  @override
  void onClose() {
    _draftSaveDebounce?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    balanceCtrl.dispose();
    riskPercentCtrl.dispose();
    entryCtrl.dispose();
    stopCtrl.dispose();
    rrTargetCtrl.dispose();
    tp1RCtrl.dispose();
    tp2RCtrl.dispose();
    tp1CloseCtrl.dispose();
    apiKeyCtrl.dispose();
    super.onClose();
  }

  void updateInstrument(Instrument instrument) {
    if (selectedInstrument.value.symbol == instrument.symbol) {
      return;
    }
    selectedInstrument.value = instrument;
    currentPriceSource.value = null;
    lastQuoteAt.value = null;
    lastError.value = '';
    _scheduleDraftSave();
    fetchLivePrice();
  }

  void updateExitMode(ExitMode mode) {
    selectedExitMode.value = mode;
    _scheduleDraftSave();
  }

  void updateBreakEven(bool value) {
    useBreakEven.value = value;
    _scheduleDraftSave();
  }

  void updateInstrumentQuery(String value) {
    instrumentQuery.value = value;
  }

  void updateInstrumentTab(String value) {
    selectedInstrumentTab.value = value;
  }

  Future<void> updatePriceProvider(PriceProvider provider) async {
    selectedPriceProvider.value = provider;
    await _storageService.writeString(_priceProviderKey, provider.name);
  }

  bool isFavorite(String symbol) => favoriteSymbols.contains(symbol);

  Future<void> toggleFavorite(String symbol) async {
    if (isFavorite(symbol)) {
      favoriteSymbols.remove(symbol);
    } else {
      favoriteSymbols.add(symbol);
    }
    await _persistFavorites();
  }

  List<Instrument> get filteredInstruments {
    final query = instrumentQuery.value.trim().toLowerCase();
    Iterable<Instrument> items = supportedInstruments;

    if (selectedInstrumentTab.value == 'favorites') {
      items = items.where((item) => isFavorite(item.symbol));
    } else if (selectedInstrumentTab.value != 'all') {
      items = items.where((item) => item.category == selectedInstrumentTab.value);
    }

    if (query.isNotEmpty) {
      items = items.where(
        (item) =>
            item.symbol.toLowerCase().contains(query) ||
            item.displayLabel.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query),
      );
    }

    final list = items.toList();
    list.sort((a, b) {
      final favA = isFavorite(a.symbol) ? 0 : 1;
      final favB = isFavorite(b.symbol) ? 0 : 1;
      if (favA != favB) {
        return favA.compareTo(favB);
      }
      return a.symbol.compareTo(b.symbol);
    });
    return list;
  }

  List<String> get availableTabs {
    final tabs = <String>{'all'};
    for (final instrument in supportedInstruments) {
      tabs.add(instrument.category);
    }
    tabs.add('favorites');
    return tabs.toList(growable: false);
  }

  Future<void> fetchLivePrice() async {
    isFetchingPrice.value = true;
    try {
      final quote = await _fetchQuoteByProvider(selectedPriceProvider.value);
      final precision = selectedInstrument.value.pricePrecision;
      currentPrice.value = quote.price;
      currentPriceSource.value = quote.source;
      lastQuoteAt.value = quote.timestamp;
      entryCtrl.text = quote.price.toStringAsFixed(precision);
      lastError.value = '';
      _scheduleDraftSave();
    } catch (error) {
      final message = error.toString();
      if (message.contains('Missing TWELVEDATA_API_KEY')) {
        lastError.value = 'Missing API key. Configure it in menu > API Configuration.';
      } else {
        lastError.value = message;
      }
    } finally {
      isFetchingPrice.value = false;
    }
  }

  void calculateRisk() {
    final balance = double.tryParse(balanceCtrl.text.trim());
    final riskPercent = double.tryParse(riskPercentCtrl.text.trim());
    final entry = double.tryParse(entryCtrl.text.trim());
    final stop = double.tryParse(stopCtrl.text.trim());

    if (balance == null || riskPercent == null || entry == null || stop == null) {
      lastError.value = 'Invalid input. Enter numeric values for balance, risk, entry, and SL.';
      return;
    }

    final stopDistance = (entry - stop).abs();
    if (stopDistance == 0) {
      lastError.value = 'Entry and SL cannot be equal.';
      return;
    }

    final direction = entry >= stop ? 1.0 : -1.0;
    final rrSimple = double.tryParse(rrTargetCtrl.text.trim()) ?? 2.0;
    final partialTp1R = double.tryParse(tp1RCtrl.text.trim()) ?? 1.0;
    final partialTp2R = double.tryParse(tp2RCtrl.text.trim()) ?? 2.0;

    if (selectedExitMode.value == ExitMode.simple && rrSimple <= 0) {
      lastError.value = 'R:R target must be greater than 0.';
      return;
    }

    if (selectedExitMode.value == ExitMode.partial && (partialTp1R <= 0 || partialTp2R <= 0)) {
      lastError.value = 'TP1R and TP2R must be greater than 0.';
      return;
    }

    final targetTp = selectedExitMode.value == ExitMode.simple
        ? (entry + (direction * stopDistance * rrSimple))
        : (entry + (direction * stopDistance * partialTp2R));

    final riskResult = _calculator.calculate(
      accountBalance: balance,
      riskPercent: riskPercent,
      entry: entry,
      stopLoss: stop,
      takeProfit: targetTp,
      instrument: selectedInstrument.value,
    );

    if (riskResult == null) {
      lastError.value = 'Could not calculate. Check entry/SL values.';
      return;
    }

    lastRiskResult.value = riskResult;
    partialPlanResult.value = null;
    simpleTpPrice.value = null;
    tp1Price.value = null;
    tp2Price.value = null;
    lastError.value = '';

    if (selectedExitMode.value == ExitMode.simple) {
      simpleTpPrice.value = targetTp;
      return;
    }

    final tp1Close = double.tryParse(tp1CloseCtrl.text.trim()) ?? 50;

    tp1Price.value = entry + (direction * stopDistance * partialTp1R);
    tp2Price.value = entry + (direction * stopDistance * partialTp2R);
    partialPlanResult.value = _calculator.calculatePartialPlan(
      riskAmount: riskResult.riskAmount,
      tp1ClosePercent: tp1Close,
      tp1R: partialTp1R,
      tp2R: partialTp2R,
    );
  }

  Future<void> copyLotSize() async {
    final result = lastRiskResult.value;
    if (result == null || result.lotSize <= 0) {
      Get.snackbar('Not available', 'Calculated lot is below broker minimum.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: result.lotSize.toStringAsFixed(2)));
    Get.snackbar('Copied', 'Lot size copied to clipboard');
  }

  double? get tp1LotSize {
    final result = lastRiskResult.value;
    if (result == null || result.lotSize <= 0 || selectedExitMode.value != ExitMode.partial) {
      return null;
    }
    final split = (double.tryParse(tp1CloseCtrl.text.trim()) ?? 50).clamp(0, 100) / 100;
    return result.lotSize * split;
  }

  double? get tp2LotSize {
    final result = lastRiskResult.value;
    if (result == null || result.lotSize <= 0 || selectedExitMode.value != ExitMode.partial) {
      return null;
    }
    final split = (double.tryParse(tp1CloseCtrl.text.trim()) ?? 50).clamp(0, 100) / 100;
    return result.lotSize * (1 - split);
  }

  bool get isCustomSplit {
    final split = (double.tryParse(tp1CloseCtrl.text.trim()) ?? 50);
    return selectedExitMode.value == ExitMode.partial && (split - 50).abs() > 0.01;
  }

  Future<void> copyTp1Lot() async {
    final lot = tp1LotSize;
    if (lot == null || lot <= 0) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: lot.toStringAsFixed(2)));
    Get.snackbar('Copied', 'TP1 lot copied');
  }

  Future<void> copyTp2Lot() async {
    final lot = tp2LotSize;
    if (lot == null || lot <= 0) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: lot.toStringAsFixed(2)));
    Get.snackbar('Copied', 'TP2 lot copied');
  }

  Future<void> savePreset(String name) async {
    final riskPercent = double.tryParse(riskPercentCtrl.text.trim());
    final tp1Close = double.tryParse(tp1CloseCtrl.text.trim()) ?? 50;
    final tp2R = double.tryParse(tp2RCtrl.text.trim()) ?? 1.5;

    if (riskPercent == null || name.trim().isEmpty) {
      lastError.value = 'Preset requires a name and valid risk %.';
      return;
    }

    final preset = TradePreset(
      name: name.trim(),
      riskPercent: riskPercent,
      tp1ClosePercent: tp1Close,
      tp2R: tp2R,
      useBreakEven: useBreakEven.value,
    );

    presets.removeWhere((item) => item.name == preset.name);
    presets.insert(0, preset);
    await _storageService.writeString(_presetKey, TradePreset.encodeMany(presets));
  }

  Future<void> deletePreset(TradePreset preset) async {
    presets.removeWhere((item) => item.name == preset.name);
    if (presets.isEmpty) {
      await _storageService.remove(_presetKey);
      return;
    }
    await _storageService.writeString(_presetKey, TradePreset.encodeMany(presets));
  }

  void applyPreset(TradePreset preset) {
    riskPercentCtrl.text = preset.riskPercent.toString();
    tp1CloseCtrl.text = preset.tp1ClosePercent.toString();
    tp2RCtrl.text = preset.tp2R.toString();
    useBreakEven.value = preset.useBreakEven;
    lastError.value = '';
    _scheduleDraftSave();
  }

  Future<void> saveApiKey(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _storageService.remove(_apiKeyStorageKey);
      apiKeyCtrl.clear();
      return;
    }

    await _storageService.writeString(_apiKeyStorageKey, trimmed);
    apiKeyCtrl.text = trimmed;
  }

  Future<void> clearApiKey() async {
    await _storageService.remove(_apiKeyStorageKey);
    apiKeyCtrl.clear();
  }

  void _loadPresets() {
    final raw = _storageService.readString(_presetKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    presets.assignAll(TradePreset.decodeMany(raw));
  }

  String get priceSourceLabel {
    switch (currentPriceSource.value) {
      case PriceSource.live:
        return 'Live';
      case PriceSource.cached:
        return 'Cached';
      case PriceSource.fallback:
        return 'Fallback';
      case null:
        return 'Manual';
    }
  }

  void _bindDraftPersistence() {
    _textControllers
      ..clear()
      ..addAll([
        balanceCtrl,
        riskPercentCtrl,
        entryCtrl,
        stopCtrl,
        rrTargetCtrl,
        tp1RCtrl,
        tp2RCtrl,
        tp1CloseCtrl,
      ]);

    for (final controller in _textControllers) {
      controller.addListener(_scheduleDraftSave);
    }

    _workers.addAll([
      ever<Instrument>(selectedInstrument, (_) => _scheduleDraftSave()),
      ever<ExitMode>(selectedExitMode, (_) => _scheduleDraftSave()),
      ever<bool>(useBreakEven, (_) => _scheduleDraftSave()),
    ]);
  }

  void _scheduleDraftSave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 350), () {
      _persistDraft();
    });
  }

  Future<void> _persistDraft() async {
    final payload = jsonEncode({
      'balance': balanceCtrl.text,
      'riskPercent': riskPercentCtrl.text,
      'entry': entryCtrl.text,
      'stop': stopCtrl.text,
      'rrTarget': rrTargetCtrl.text,
      'tp1R': tp1RCtrl.text,
      'tp2R': tp2RCtrl.text,
      'tp1Close': tp1CloseCtrl.text,
      'selectedSymbol': selectedInstrument.value.symbol,
      'exitMode': selectedExitMode.value.name,
      'useBreakEven': useBreakEven.value,
    });
    await _storageService.writeString(_draftKey, payload);
  }

  Future<void> _persistFavorites() async {
    await _storageService.writeString(_favoritesKey, jsonEncode(favoriteSymbols));
  }

  void _loadDraft() {
    final providerRaw = _storageService.readString(_priceProviderKey);
    if (providerRaw != null) {
      final provider = PriceProvider.values.where((item) => item.name == providerRaw).firstOrNull;
      if (provider != null) {
        selectedPriceProvider.value = provider;
      }
    }

    final apiKey = _storageService.readString(_apiKeyStorageKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      apiKeyCtrl.text = apiKey;
    }

    final favoriteRaw = _storageService.readString(_favoritesKey);
    if (favoriteRaw != null && favoriteRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(favoriteRaw) as List<dynamic>;
        favoriteSymbols.assignAll(decoded.map((e) => e.toString()));
      } catch (_) {
        favoriteSymbols.clear();
      }
    }

    final raw = _storageService.readString(_draftKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      balanceCtrl.text = map['balance']?.toString() ?? balanceCtrl.text;
      riskPercentCtrl.text = map['riskPercent']?.toString() ?? riskPercentCtrl.text;
      entryCtrl.text = map['entry']?.toString() ?? entryCtrl.text;
      stopCtrl.text = map['stop']?.toString() ?? stopCtrl.text;
      rrTargetCtrl.text = map['rrTarget']?.toString() ?? rrTargetCtrl.text;
      tp1RCtrl.text = map['tp1R']?.toString() ?? tp1RCtrl.text;
      tp2RCtrl.text = map['tp2R']?.toString() ?? tp2RCtrl.text;
      tp1CloseCtrl.text = map['tp1Close']?.toString() ?? tp1CloseCtrl.text;

      final symbol = map['selectedSymbol']?.toString();
      if (symbol != null) {
        final instrument = supportedInstruments.where((i) => i.symbol == symbol).firstOrNull;
        if (instrument != null) {
          selectedInstrument.value = instrument;
        }
      }

      final exitModeName = map['exitMode']?.toString();
      if (exitModeName != null) {
        final mode = ExitMode.values.where((item) => item.name == exitModeName).firstOrNull;
        if (mode != null) {
          selectedExitMode.value = mode;
        }
      }

      useBreakEven.value = map['useBreakEven'] == true;
    } catch (_) {
      // ignore corrupted draft
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersionLabel.value = 'v${info.version} (${info.buildNumber})';
    } catch (_) {
      appVersionLabel.value = 'v1.0.0 (1)';
    }
  }

  Future<PriceQuote> _fetchQuoteByProvider(PriceProvider provider) async {
    if (provider == PriceProvider.yahooFinance) {
      return _yahooPriceService.getLatestPrice(selectedInstrument.value.symbol);
    }

    try {
      return await _priceService.getLatestPrice(selectedInstrument.value.symbol);
    } catch (_) {
      return _yahooPriceService.getLatestPrice(selectedInstrument.value.symbol);
    }
  }
}
