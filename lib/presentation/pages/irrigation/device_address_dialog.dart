import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:airri_mobile/infrastructure/irrigation/device_settings_service.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

// Dialog untuk mengganti alamat IP ESP32 (base_url). Tidak ada di
// prototype HTML, tapi diperlukan supaya app bisa dipakai di jaringan
// WiFi mana saja. Postman collection-nya sendiri punya variable
// base_url yang bisa diganti-ganti.
Future<void> showDeviceAddressDialog(
  BuildContext context,
  DeviceSettingsService deviceSettings, {
  VoidCallback? onSaved,
}) async {
  final controller = TextEditingController(text: deviceSettings.baseUrl);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrrigationColors.radiusMd),
      ),
      title: Text('device_address.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'device_address.body'.tr(),
            style: const TextStyle(fontSize: 12.5, color: IrrigationColors.ink500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'http://192.168.1.100',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr(),
              style: const TextStyle(color: IrrigationColors.ink500)),
        ),
        TextButton(
          onPressed: () async {
            await deviceSettings.setBaseUrl(controller.text);
            if (context.mounted) Navigator.of(context).pop();
            onSaved?.call();
          },
          child: Text('common.save'.tr(),
              style: const TextStyle(
                  color: IrrigationColors.green600, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
