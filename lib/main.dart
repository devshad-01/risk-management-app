import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riskflow_fx/core/constants/instruments.dart';
import 'package:riskflow_fx/core/theme/app_theme.dart';
import 'package:riskflow_fx/features/risk/controllers/trade_controller.dart';
import 'package:riskflow_fx/features/risk/services/cached_price_service.dart';
import 'package:riskflow_fx/features/risk/services/local_storage_service.dart';
import 'package:riskflow_fx/features/risk/services/twelvedata_price_service.dart';
import 'package:riskflow_fx/features/risk/ui/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await LocalStorageService.create();
  const envApiKey = String.fromEnvironment('TWELVEDATA_API_KEY');
  if (envApiKey.isNotEmpty) {
    await storageService.writeString('twelvedata_api_key', envApiKey);
  }

  final priceService = CachedPriceService(
    primary: TwelveDataPriceService(
      apiKeyResolver: () => storageService.readString('twelvedata_api_key'),
    ),
    storageService: storageService,
    instruments: supportedInstruments,
  );

  Get.put<TradeController>(
    TradeController(
      priceService: priceService,
      storageService: storageService,
    ),
    permanent: true,
  );

  runApp(const RiskFlowApp());
}

class RiskFlowApp extends StatelessWidget {
  const RiskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RiskFlow FX',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      home: const SplashPage(),
    );
  }
}
