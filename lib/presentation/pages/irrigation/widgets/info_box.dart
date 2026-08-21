import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'irrigation_card.dart';

class InfoBox extends StatelessWidget {
  final String text;
  final bool amber;

  const InfoBox({super.key, required this.text, this.amber = false});

  @override
  Widget build(BuildContext context) {
    final color = amber ? IrrigationColors.amber600 : IrrigationColors.blue600;
    return IrrigationCard(
      tint: amber ? CardTint.amber : CardTint.blue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('i',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, height: 1.5, color: color)),
          ),
        ],
      ),
    );
  }
}
