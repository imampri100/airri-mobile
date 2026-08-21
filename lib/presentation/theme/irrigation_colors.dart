import 'package:flutter/material.dart';

// diambil dari smart-irrigation-prototype_final.html, bagian "5. Design Tokens"
class IrrigationColors {
  IrrigationColors._();

  static const green700 = Color(0xFF0F6B3C);
  static const green600 = Color(0xFF1A8A52);
  static const green500 = Color(0xFF22A05F);
  static const green100 = Color(0xFFE4F6EC);
  static const green50 = Color(0xFFF1FAF5);

  static const red600 = Color(0xFFDC2626);
  static const red100 = Color(0xFFFDE8E8);
  static const red50 = Color(0xFFFEF3F3);

  static const blue600 = Color(0xFF2563EB);
  static const blue100 = Color(0xFFDCEAFE);
  static const blue50 = Color(0xFFEFF6FF);

  static const amber600 = Color(0xFFC2410C);
  static const amber100 = Color(0xFFFDE7D2);
  static const amber50 = Color(0xFFFFF7ED);

  static const ink900 = Color(0xFF15181C);
  static const ink700 = Color(0xFF374151);
  static const ink500 = Color(0xFF6B7280);
  static const ink300 = Color(0xFF9CA3AF);

  static const line200 = Color(0xFFE7E9EC);
  static const line100 = Color(0xFFF0F1F3);

  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF4F5F7);

  // sensor swatch colors (dari .swatch.moisture/.humidity/.temp/.light)
  static const moisture = Color(0xFF8B6A45);
  static const humidity = Color(0xFF2E86DE);
  static const temperature = Color(0xFFE05252);
  static const light = Color(0xFFE0A72E);

  static const radiusLg = 20.0;
  static const radiusMd = 14.0;
  static const radiusSm = 10.0;
}
