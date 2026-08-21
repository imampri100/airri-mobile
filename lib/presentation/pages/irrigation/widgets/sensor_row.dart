import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

enum SensorKind { moisture, humidity, temperature, light }

class SensorRow extends StatelessWidget {
  final SensorKind kind;
  final String label;
  final String value;
  final bool showDivider;

  const SensorRow({
    super.key,
    required this.kind,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  ({Color color, String emoji}) get _style {
    switch (kind) {
      case SensorKind.moisture:
        return (color: IrrigationColors.moisture, emoji: '💧');
      case SensorKind.humidity:
        return (color: IrrigationColors.humidity, emoji: '💧');
      case SensorKind.temperature:
        return (color: IrrigationColors.temperature, emoji: '🌡️');
      case SensorKind.light:
        return (color: IrrigationColors.light, emoji: '☀️');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: IrrigationColors.line100),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(s.emoji, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 9),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: IrrigationColors.ink700)),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: IrrigationColors.ink900)),
        ],
      ),
    );
  }
}
