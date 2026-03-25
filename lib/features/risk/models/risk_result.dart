class RiskResult {
  const RiskResult({
    required this.lotSize,
    required this.rawLotSize,
    required this.riskAmount,
    required this.effectiveRiskAmount,
    required this.isBelowMinLot,
    required this.minLot,
    required this.stopLossPips,
    required this.rewardAmount,
    required this.rrRatio,
  });

  final double lotSize;
  final double rawLotSize;
  final double riskAmount;
  final double effectiveRiskAmount;
  final bool isBelowMinLot;
  final double minLot;
  final double stopLossPips;
  final double rewardAmount;
  final double rrRatio;
}

class PartialPlanResult {
  const PartialPlanResult({
    required this.tp1Profit,
    required this.tp2Profit,
    required this.totalProfit,
  });

  final double tp1Profit;
  final double tp2Profit;
  final double totalProfit;
}
