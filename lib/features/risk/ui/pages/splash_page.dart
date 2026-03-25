import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riskflow_fx/core/theme/app_theme.dart';
import 'package:riskflow_fx/features/risk/controllers/trade_controller.dart';
import 'package:riskflow_fx/features/risk/ui/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final controller = Get.find<TradeController>();
    if (controller.entryCtrl.text.trim().isEmpty) {
      await controller.fetchLivePrice();
    }
    if (!mounted) {
      return;
    }
    Get.off(() => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<TradeController>();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              color: AppTheme.brandPrimary,
              alignment: Alignment.center,
              child: const Text(
                'RR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 34,
              width: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              'RiskFlow FX',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Preparing trading workspace...',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Obx(
              () => Text(
                controller.appVersionLabel.value,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
