import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

enum CardTint { none, green, blue, red, amber }

// dari .card / .card.tint-* di prototype HTML-nya
class IrrigationCard extends StatelessWidget {
  final Widget child;
  final CardTint tint;
  final EdgeInsetsGeometry padding;

  const IrrigationCard({
    super.key,
    required this.child,
    this.tint = CardTint.none,
    this.padding = const EdgeInsets.all(14),
  });

  ({Color bg, Color border}) get _colors {
    switch (tint) {
      case CardTint.green:
        return (bg: IrrigationColors.green50, border: IrrigationColors.green100);
      case CardTint.blue:
        return (bg: IrrigationColors.blue50, border: IrrigationColors.blue100);
      case CardTint.red:
        return (bg: IrrigationColors.red50, border: IrrigationColors.red100);
      case CardTint.amber:
        return (bg: IrrigationColors.amber50, border: IrrigationColors.amber100);
      case CardTint.none:
        return (bg: IrrigationColors.surface, border: IrrigationColors.line200);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(IrrigationColors.radiusMd),
      ),
      child: child,
    );
  }
}

class CardTitle extends StatelessWidget {
  final String text;
  const CardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: IrrigationColors.ink700,
        ),
      ),
    );
  }
}
