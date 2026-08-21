import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

Future<bool> showIrrigationConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrrigationColors.radiusMd),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      content: Text(message,
          style: const TextStyle(fontSize: 13, color: IrrigationColors.ink700)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('common.cancel'.tr(),
              style: const TextStyle(color: IrrigationColors.ink500)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: danger ? IrrigationColors.red600 : IrrigationColors.green600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
