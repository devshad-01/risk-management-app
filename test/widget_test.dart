import 'package:flutter_test/flutter_test.dart';
import 'package:riskflow_fx/core/constants/instruments.dart';
import 'package:riskflow_fx/features/risk/domain/risk_calculator.dart';

void main() {
  test('risk calculator returns normalized lot size', () {
    const calculator = RiskCalculator();
    final instrument = supportedInstruments.first;

    final result = calculator.calculate(
      accountBalance: 10000,
      riskPercent: 1,
      entry: 1.1000,
      stopLoss: 1.0980,
      takeProfit: 1.1040,
      instrument: instrument,
    );

    expect(result, isNotNull);
    expect(result!.lotSize, greaterThan(0));
    expect(result.rrRatio, greaterThan(0));
  });
}
