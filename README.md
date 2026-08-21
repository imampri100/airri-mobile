# airri — Smart Irrigation Mobile App

Flutter companion app for a Smart Irrigation ESP32 device. Connects directly
to the ESP32's REST API over local WiFi to monitor sensors, control the pump,
configure automation rules, and review history/trend data synced to a local
SQLite cache.

This is the mobile side of a skripsi (undergraduate thesis) project; the
ESP32 firmware and its REST API are a separate repository/component
(`smart-irrigation-api_postman_collection.json` in that repo's `docs/`
documents that API's endpoints and example responses).

## Features

- **Dashboard** — live sensor readings (soil moisture, air humidity/temperature,
  light intensity), current pump status, trigger/restriction condition
  evaluation, and a warning banner if the device's RTC/NTP time isn't
  synchronized (log timestamps may be unreliable in that case).
- **History** — synced sensor and irrigation logs, paginated from the
  device's log endpoints with incremental sync and gap detection (flags
  ranges of data lost on the device before the app could sync them).
- **Statistik** — trend charts (soil moisture, water usage) over 7 Hari /
  30 Hari / 1 Tahun / 3 Tahun / Semua, with chart granularity that coarsens
  as the range grows (day → week → month) so multi-year data stays
  readable. Query results are cached per period and invalidated
  automatically when new data syncs in.
- **Pemicu (Trigger)** — configure the soil-moisture condition that starts
  irrigation.
- **Batasan (Restriction)** — configure conditions that block irrigation even
  when the trigger is met (humidity/temperature/light thresholds), plus a
  max pump runtime safety limit.
- Bilingual UI (Indonesian/English) via `easy_localization`.

## Architecture

Clean-architecture-ish layering under `lib/`:

```
lib/
├── domain/irrigation/          # entities, repository/local-store interfaces — no I/O
├── application/irrigation/     # cubits (state) + SyncService (use case orchestration)
├── infrastructure/irrigation/  # Dio API client, DTOs, sqflite local store
└── presentation/pages/irrigation/  # pages, widgets, theme
```

- **State management**: `flutter_bloc` (Cubit).
- **DI**: `get_it` + `injectable` (generated bindings in `injection.config.dart`).
- **Networking**: `dio`, talking directly to the ESP32's local IP (no cloud
  backend — the device address is configurable in-app since it depends on
  whatever WiFi network the ESP32 joins).
- **Local persistence**: `sqflite` — sensor/irrigation logs are synced
  incrementally and cached locally so History/Statistik don't need to hit
  the device on every screen open.

## Getting started

```bash
flutter pub get
flutter run
```

The app defaults to a placeholder device IP (`DeviceSettingsService`) — set
the real ESP32 address from the in-app "Alamat Perangkat" menu, or via the
`⋮` overflow menu on any page. See the firmware repo's
`docs/smart-irrigation-api_postman_collection.json` for the API this app
talks to.

## Updating branding assets

- **App icon**: edit `assets/icon/`, then `dart run flutter_launcher_icons`.
- **Splash screen**: edit `flutter_native_splash.yaml` / assets in
  `assets/images/`, then `dart run flutter_native_splash:create`. Android
  12+ renders the center icon and the wordmark ("branding" image) as two
  separate layers — the center icon gets clipped to a circle, the branding
  image does not, so any text needs to go in `branding`, not `image`.
- **App display name**: `android:label` in
  `android/app/src/main/AndroidManifest.xml`, `CFBundleDisplayName` /
  `CFBundleName` in `ios/Runner/Info.plist`.

See `CHANGELOG.md` for what's changed and why.
