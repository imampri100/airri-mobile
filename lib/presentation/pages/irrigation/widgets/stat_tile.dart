import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

// Tile ringkasan: ikon + label + nilai. Versi Flutter dari .stat-tile
// prototype. Disusun vertikal (ikon bulat, label kecil, nilai+satuan)
// supaya label tidak wrap walau tile-nya sempit, dipakai berjajar
// dalam satu Row (3 tile di Dashboard/Statistik).
class StatTile extends StatelessWidget {
  final Color iconColor;
  final String emoji;
  final String label;
  final String value;
  final String unit;

  const StatTile({
    super.key,
    required this.iconColor,
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: IrrigationColors.green50,
          border: Border.all(color: IrrigationColors.green100),
          borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
        ),
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: IrrigationColors.ink500),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: IrrigationColors.ink900,
                ),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: IrrigationColors.ink500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
