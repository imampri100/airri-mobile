# Changelog

All notable changes to the Airri Mobile app are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/).

## 2026-07-25 to 2026-07-27

### Added
- **Global connectivity indicator** — new `ConnectivityCubit` polls the
  firmware's `GET /api/ping` every 15s (a lightweight endpoint that touches
  neither sensors nor the SD card) and drives a connection badge now shown
  in the app bar on all 5 tabs, not just Beranda. Previously the badge only
  reflected on-demand Dashboard refreshes and was invisible elsewhere.
- **Pump flow rate now read from the device** — added `GET /api/pump/info`
  support. The Trigger page's "Debit Pompa" field is a fixed hardware spec
  (not user-configurable), so it's rendered read-only and its value/info
  copy now reflects the real firmware constant instead of a hardcoded,
  never-synced local default.
- **Device language sync** — toggling the app's language now also calls the
  firmware's new `PUT /api/settings/language`, so `decision.reason` and the
  device's TFT screen match the app's language. Best-effort: switching the
  app's language never blocks on device reachability.
- **Explicit error states on Trigger/Restriction pages** — a failed
  `GET /api/settings/trigger` or `/restriction` used to render the page with
  silently-guessed fallback values, indistinguishable from real device data.
  Both pages now show a red error banner with a retry action instead.

### Fixed
- **`RestrictionSetting` fallback values were wrong** — the placeholder
  shown before the first successful fetch (or after a failed one) had
  humidity restriction enabled by default with different operator/threshold
  values than the firmware actually ships with. Fallback now matches the
  real firmware defaults exactly (all three conditions disabled).
- **Rebranded in-app name to "airri"** — the AppBar title, "Tentang
  Perangkat" dialog, and `MaterialApp.title` still said "Smart Irrigation"
  after the app label/splash wordmark had already been changed to "airri".
- **Leftover untranslated/mixed-language strings** — several Indonesian
  locale strings mixed in English words (`soil moisture`, `restriction`,
  `flow rate`, `trigger`) or were ambiguous ("Kelembapan" on the Restriction
  page, which is air humidity, read the same as "Kelembapan Tanah" on the
  Trigger page). Also moved the Trigger page's two info boxes to sit under
  their respective fields instead of both stacked at the bottom.
- Updated the default device base URL placeholder in `DeviceSettingsService`.
- **History page could hang indefinitely on load** — the shared `Dio`
  instance (`DioDi`) never set `connectTimeout`, so `sendTimeout`/
  `receiveTimeout` (which only guard the request/response phase) didn't
  cover a stalled TCP handshake when the device was unreachable. A slow or
  unresponsive device could leave the History loading spinner spinning far
  longer than intended. `connectTimeout` is now set to 8s, so an
  unreachable device fails fast and falls back to the local SQLite cache
  instead.

## 2026-07-23

### Added
- **Device time-sync warning banner** — the ESP32's `GET /api/status` response
  includes a `timeSynchronized` field (RTC failed and NTP fallback also
  failed) that the app previously ignored. `DeviceStatus` now carries this
  flag, and Dashboard shows an amber warning banner when it's `false`, so
  users know log timestamps may be unreliable for that window.
- **1 Year / 3 Years periods on Statistik** — the period selector only had
  7 Hari / 30 Hari / Semua. Added "1 Tahun" and "3 Tahun", with chart point
  granularity that coarsens as the range grows (day → week → month), so a
  multi-year chart doesn't render as an unreadable wall of daily noise. The
  period pill row is now horizontally scrollable to fit five options.
- **Per-period result caching in Statistik** — switching between period tabs
  re-queried SQLite every time even when nothing had changed. Results are now
  cached per period in `StatistikCubit` and only recomputed when
  `SyncService` reports new data (a `dataVersion` counter) or the date range
  itself shifts (e.g. app left open across midnight). Pull-to-refresh still
  forces a fresh query.
- **App branding** — app label changed from "airri_mobile"/"Airri Mobile" to
  lowercase "airri" (Android manifest + iOS Info.plist). The Android 12+
  splash screen, which previously showed only the icon mark, now also shows
  the "airri" wordmark as a branding image anchored below the icon (the
  pre-12/iOS splash composite already had it).

### Fixed
- **Operator dropdown misalignment** in Trigger/Restriction condition
  fields — the operator `DropdownButton` didn't set `isDense: true` like its
  neighboring `TextField`, so it rendered taller and the pills didn't line
  up. Added `isDense: true` to match.

### Verified (no code change)
- Audited the mobile app's API client against the ESP32 firmware's Postman
  collection: all 13 endpoints are implemented and wired to the correct
  path. `startPump`/`stopPump` are implemented end-to-end but never called
  from any UI — left as-is pending a product decision on manual pump
  on/off control.
- Confirmed the Statistik "Semua" (all-time) period is not a hang risk even
  under heavy data volume: stress-tested with ~318k synthetic sensor rows
  spanning 3 years (SQL `GROUP BY` aggregation + indexed `createdAt`, chart
  only ever receives one point per day/week/month bucket, never raw rows).
