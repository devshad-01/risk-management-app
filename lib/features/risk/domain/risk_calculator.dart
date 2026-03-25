import 'dart:math';

import 'package:riskflow_fx/features/risk/models/instrument.dart';
import 'package:riskflow_fx/features/risk/models/risk_result.dart';

class RiskCalculator {
  const RiskCalculator();

  RiskResult? calculate({
    required double accountBalance,
    required double riskPercent,
    required double entry,
    required double stopLoss,
    required double? takeProfit,
    required Instrument instrument,
  }) {
    if (accountBalance <= 0 || riskPercent <= 0 || entry <= 0 || stopLoss <= 0) {
      return null;
    }

    final stopDistance = (entry - stopLoss).abs();
    if (stopDistance == 0) {
      return null;
    }

    final stopLossPips = stopDistance / instrument.pipSize;
    if (stopLossPips <= 0) {
      return null;
    }

    final riskAmount = accountBalance * (riskPercent / 100);
    final rawLot = riskAmount / (stopLossPips * instrument.pipValuePerStandardLot);
    final normalizedLot = _normalizeLot(rawLot, instrument);
    final isBelowMinLot = normalizedLot < instrument.minLot;
    final effectiveRiskAmount =
      normalizedLot * stopLossPips * instrument.pipValuePerStandardLot;

    double rewardAmount = 0;
    double rrRatio = 0;

    if (takeProfit != null && takeProfit > 0) {
      final rewardDistance = (takeProfit - entry).abs();
      rrRatio = rewardDistance / stopDistance;
      rewardAmount = riskAmount * rrRatio;
    }

    return RiskResult(
      lotSize: normalizedLot,
      rawLotSize: rawLot,
      riskAmount: riskAmount,
      effectiveRiskAmount: effectiveRiskAmount,
      isBelowMinLot: isBelowMinLot,
      minLot: instrument.minLot,
      stopLossPips: stopLossPips,
      rewardAmount: rewardAmount,
      rrRatio: rrRatio,
    );
  }

  PartialPlanResult calculatePartialPlan({
    required double riskAmount,
    required double tp1ClosePercent,
    required double tp1R,
    required double tp2R,
  }) {
    final tp1Fraction = (tp1ClosePercent / 100).clamp(0.0, 1.0);
    final remainder = 1 - tp1Fraction;

    final tp1Profit = riskAmount * tp1R * tp1Fraction;
    final tp2Profit = riskAmount * tp2R * remainder;
    return PartialPlanResult(
      tp1Profit: tp1Profit,
      tp2Profit: tp2Profit,
      totalProfit: tp1Profit + tp2Profit,
    );
  }

  double _normalizeLot(double rawLot, Instrument instrument) {
    if (rawLot <= 0) {
      return 0;
    }

    final steps = (rawLot / instrument.lotStep).floor();
    final adjusted = steps * instrument.lotStep;
    return max(0, adjusted);
  }
}
