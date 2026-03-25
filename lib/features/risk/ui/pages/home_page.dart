import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riskflow_fx/core/theme/app_theme.dart';
import 'package:riskflow_fx/features/risk/controllers/trade_controller.dart';

class HomePage extends GetView<TradeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<_MenuAction>(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          position: PopupMenuPosition.under,
          offset: const Offset(0, 4),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppTheme.brandSecondary, width: 0.8),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem<_MenuAction>(
              value: _MenuAction.settings,
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: AppTheme.brandSecondary),
                  SizedBox(width: 8),
                  Text(
                    'API Configuration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            const PopupMenuItem<_MenuAction>(
              enabled: false,
              child: SizedBox(
                width: 220,
                child: Text(
                  'For educational purposes / not financial advice',
                  style: TextStyle(fontSize: 12, color: AppTheme.brandSecondary),
                ),
              ),
            ),
          ],
          onSelected: (action) {
            if (action == _MenuAction.settings) {
              _showApiKeyDialog(context);
            }
          },
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 250),
                    children: [
                      Obx(() {
                        final tabs = controller.availableTabs;
                        final selected = controller.selectedInstrumentTab.value;
                        return SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: tabs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final tab = tabs[index];
                              return ChoiceChip(
                                label: Text(
                                  _tabLabel(tab),
                                  style: TextStyle(
                                    color: selected == tab ? const Color(0xFF06231F) : Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                selected: selected == tab,
                                onSelected: (_) => controller.updateInstrumentTab(tab),
                                showCheckmark: false,
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Obx(() {
                        final selectedInstrument = controller.selectedInstrument.value;
                        final filtered = controller.filteredInstruments;
                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.zero,
                                onTap: () => _showInstrumentSheet(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Instrument'),
                                  child: Text(
                                    filtered.isEmpty
                                        ? 'No instrument in this filter'
                                        : selectedInstrument.displayLabel,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () => controller.toggleFavorite(selectedInstrument.symbol),
                              tooltip: controller.isFavorite(selectedInstrument.symbol)
                                  ? 'Remove favorite'
                                  : 'Add favorite',
                              icon: Icon(
                                controller.isFavorite(selectedInstrument.symbol)
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 10),
                      _numberField(controller.balanceCtrl, 'Account Balance'),
                      const SizedBox(height: 10),
                      _numberField(controller.riskPercentCtrl, 'Risk %'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => TextField(
                                controller: controller.entryCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Entry Price',
                                  suffixIcon: controller.isFetchingPrice.value
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: controller.fetchLivePrice,
                                          icon: const Icon(Icons.refresh_rounded),
                                          tooltip: 'Refresh live price',
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _numberField(controller.stopCtrl, 'Stop Loss Price'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Obx(
                        () => Row(
                          children: [
                            Expanded(
                              child: _modeButton(
                                label: 'Simple',
                                selected: controller.selectedExitMode.value == ExitMode.simple,
                                onTap: () => controller.updateExitMode(ExitMode.simple),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _modeButton(
                                label: 'Partial',
                                selected: controller.selectedExitMode.value == ExitMode.partial,
                                onTap: () => controller.updateExitMode(ExitMode.partial),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        if (controller.selectedExitMode.value == ExitMode.simple) {
                          return _numberField(controller.rrTargetCtrl, 'Target R:R (e.g. 2.0)');
                        }

                        return Column(
                          children: [
                            _numberField(controller.tp1CloseCtrl, 'TP1 Close % (e.g. 50)'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _numberField(controller.tp1RCtrl, 'TP1 R')),
                                const SizedBox(width: 10),
                                Expanded(child: _numberField(controller.tp2RCtrl, 'TP2 R')),
                              ],
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: controller.calculateRisk,
                        child: const Text('Calculate'),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final err = controller.lastError.value;
                        if (err.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Text(err, style: const TextStyle(color: Colors.redAccent));
                      }),
                    ],
                  ),
                ),
                _resultOverlay(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _resultOverlay(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Obx(() {
        final result = controller.lastRiskResult.value;
        final partial = controller.partialPlanResult.value;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111A26),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: result == null
              ? const Text('Calculated result appears here')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lot Size: ${result.lotSize.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text('Risk: ${result.riskAmount.toStringAsFixed(2)}'),
                    Text('SL Distance: ${result.stopLossPips.toStringAsFixed(1)} pips'),
                    if (controller.selectedExitMode.value == ExitMode.simple &&
                        controller.simpleTpPrice.value != null)
                      Text('TP Price: ${controller.simpleTpPrice.value!.toStringAsFixed(controller.selectedInstrument.value.pricePrecision)}'),
                    if (controller.selectedExitMode.value == ExitMode.partial &&
                        controller.tp1Price.value != null &&
                        controller.tp2Price.value != null)
                      Text(
                        'TP1: ${controller.tp1Price.value!.toStringAsFixed(controller.selectedInstrument.value.pricePrecision)} '
                        '• TP2: ${controller.tp2Price.value!.toStringAsFixed(controller.selectedInstrument.value.pricePrecision)}',
                      ),
                    if (partial != null) ...[
                      const SizedBox(height: 6),
                      Text('Profit TP1: ${partial.tp1Profit.toStringAsFixed(2)}'),
                      Text('Profit TP2: ${partial.tp2Profit.toStringAsFixed(2)}'),
                      Text('Blended Total: ${partial.totalProfit.toStringAsFixed(2)}'),
                    ],
                    const SizedBox(height: 8),
                    if (controller.isCustomSplit)
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: controller.tp1LotSize != null && controller.tp1LotSize! > 0
                                  ? controller.copyTp1Lot
                                  : null,
                              child: Text(
                                'Copy TP1 ${controller.tp1LotSize?.toStringAsFixed(2) ?? '--'}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: controller.tp2LotSize != null && controller.tp2LotSize! > 0
                                  ? controller.copyTp2Lot
                                  : null,
                              child: Text(
                                'Copy TP2 ${controller.tp2LotSize?.toStringAsFixed(2) ?? '--'}',
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      FilledButton.tonal(
                        onPressed: result.lotSize > 0 ? controller.copyLotSize : null,
                        child: const Text('Copy Lot Size'),
                      ),
                  ],
                ),
        );
      }),
    );
  }

  Widget _numberField(TextEditingController inputController, String label) {
    return TextField(
      controller: inputController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final localController = TextEditingController(text: controller.apiKeyCtrl.text);
    var selectedMode = controller.selectedPriceMode.value;
    var selectedProvider = controller.selectedPriceProvider.value;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Configuration',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    const Text('Price Mode'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _modeButton(
                            label: 'Manual',
                            selected: selectedMode == PriceMode.manual,
                            onTap: () => setState(() => selectedMode = PriceMode.manual),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _modeButton(
                            label: 'Auto',
                            selected: selectedMode == PriceMode.auto,
                            onTap: () => setState(() => selectedMode = PriceMode.auto),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedMode == PriceMode.auto) ...[
                      DropdownButtonFormField<PriceProvider>(
                        initialValue: selectedProvider,
                        decoration: const InputDecoration(labelText: 'Provider'),
                        items: const [
                          DropdownMenuItem(
                            value: PriceProvider.twelveData,
                            child: Text('Twelve Data (Yahoo backup)'),
                          ),
                          DropdownMenuItem(
                            value: PriceProvider.yahooFinance,
                            child: Text('Yahoo Finance'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedProvider = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      if (selectedProvider == PriceProvider.twelveData)
                        TextField(
                          controller: localController,
                          decoration: const InputDecoration(
                            labelText: 'TwelveData API Key',
                            hintText: 'Paste key here',
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'For educational purposes / not financial advice',
                      style: TextStyle(fontSize: 12, color: AppTheme.brandSecondary),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Text(
                        controller.appVersionLabel.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            controller.clearApiKey();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear Key'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            await controller.updatePriceMode(selectedMode);
                            await controller.updatePriceProvider(selectedProvider);
                            if (selectedProvider == PriceProvider.twelveData) {
                              await controller.saveApiKey(localController.text);
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            if (selectedMode == PriceMode.auto) {
                              await controller.fetchLivePrice();
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showInstrumentSheet(BuildContext context) async {
    final instruments = controller.filteredInstruments;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: instruments.isEmpty
                ? const Center(child: Text('No instruments found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: instruments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final instrument = instruments[index];
                      return ListTile(
                        title: Text(instrument.displayLabel),
                        subtitle: Text(instrument.category.toUpperCase()),
                        onTap: () {
                          controller.updateInstrument(instrument);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  String _tabLabel(String tab) {
    switch (tab) {
      case 'all':
        return 'All';
      case 'forex':
        return 'Forex';
      case 'metal':
        return 'Metals';
      case 'index':
        return 'Indices';
      case 'crypto':
        return 'Crypto';
      case 'favorites':
        return 'Favorites';
      default:
        return tab;
    }
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: selected
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF06231F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: AppTheme.brandSecondary.withValues(alpha: 0.8), width: 0.8),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

enum _MenuAction { settings }
