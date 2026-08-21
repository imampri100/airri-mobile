import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'irrigation_card.dart';

// versi Flutter dari .banner (icon bulat + judul + subjudul). dipake
// buat banner sync/offline/error di dashboard & history
class StatusBanner extends StatelessWidget {
  final CardTint tint;
  final Color iconColor;
  final String icon;
  final String title;
  final String? subtitle;
  final double? progress; // 0..1, null = tidak ada progress bar
  final Widget? trailing;

  const StatusBanner({
    super.key,
    required this.tint,
    required this.iconColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.progress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return IrrigationCard(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(icon,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: IrrigationColors.ink900)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 11.5, color: IrrigationColors.ink500)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: IrrigationColors.line100,
                valueColor:
                    const AlwaysStoppedAnimation(IrrigationColors.green500),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(progress! * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 11, color: IrrigationColors.ink500)),
            ),
          ],
        ],
      ),
    );
  }
}
