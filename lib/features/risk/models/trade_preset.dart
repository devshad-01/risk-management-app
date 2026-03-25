import 'dart:convert';

class TradePreset {
  const TradePreset({
    required this.name,
    required this.riskPercent,
    required this.tp1ClosePercent,
    required this.tp2R,
    required this.useBreakEven,
  });

  final String name;
  final double riskPercent;
  final double tp1ClosePercent;
  final double tp2R;
  final bool useBreakEven;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'riskPercent': riskPercent,
      'tp1ClosePercent': tp1ClosePercent,
      'tp2R': tp2R,
      'useBreakEven': useBreakEven,
    };
  }

  factory TradePreset.fromMap(Map<String, dynamic> map) {
    return TradePreset(
      name: map['name'] as String,
      riskPercent: (map['riskPercent'] as num).toDouble(),
      tp1ClosePercent: (map['tp1ClosePercent'] as num).toDouble(),
      tp2R: (map['tp2R'] as num).toDouble(),
      useBreakEven: map['useBreakEven'] as bool,
    );
  }

  static String encodeMany(List<TradePreset> presets) {
    return jsonEncode(presets.map((preset) => preset.toMap()).toList());
  }

  static List<TradePreset> decodeMany(String rawJson) {
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((dynamic item) => TradePreset.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
