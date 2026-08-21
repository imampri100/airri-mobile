# Panduan Lengkap Menjalankan airri (ESP32 + Mobile App)

Panduan ini membahas dari nol sampai sistem jalan: merakit & flash ESP32,
menyiapkan SD Card, build & install app Flutter, lalu menghubungkan
keduanya. Tiap langkah dilengkapi **apa yang perlu diperhatikan**, **opsi
yang tersedia**, dan **apa yang dilakukan kalau gagal**.

Detail teknis yang lebih dalam ada di README masing-masing project — panduan
ini merujuk ke sana di tiap langkah yang relevan.

---

## Daftar Isi

- [0. Gambaran Sistem](#0-gambaran-sistem)
- [1. Kebutuhan & Versi](#1-kebutuhan--versi)
- [2. ESP32 (Firmware)](#2-esp32-firmware)
  - [2.1 Install PlatformIO](#21-install-platformio)
  - [2.2 Rakit Hardware](#22-rakit-hardware)
  - [2.3 Siapkan SD Card](#23-siapkan-sd-card)
  - [2.4 Konfigurasi di Kode (Opsional)](#24-konfigurasi-di-kode-opsional)
  - [2.5 Build](#25-build)
  - [2.6 Upload ke ESP32](#26-upload-ke-esp32)
  - [2.7 Serial Monitor & Verifikasi](#27-serial-monitor--verifikasi)
  - [2.8 Kalibrasi Soil Moisture](#28-kalibrasi-soil-moisture)
  - [2.9 Uji API tanpa App (Opsional)](#29-uji-api-tanpa-app-opsional)
- [3. Mobile App (Flutter)](#3-mobile-app-flutter)
  - [3.1 Install Flutter & Tools](#31-install-flutter--tools)
  - [3.2 Ambil Dependency](#32-ambil-dependency)
  - [3.3 Siapkan Device Target](#33-siapkan-device-target)
  - [3.4 Jalankan App (Mode Development)](#34-jalankan-app-mode-development)
  - [3.5 Build APK / IPA](#35-build-apk--ipa)
  - [3.6 Install APK ke HP](#36-install-apk-ke-hp)
- [4. Menghubungkan App ke ESP32](#4-menghubungkan-app-ke-esp32)
  - [4.1 Connect HP ke WiFi ESP32](#41-connect-hp-ke-wifi-esp32)
  - [4.2 Atur Alamat Perangkat](#42-atur-alamat-perangkat)
  - [4.3 Fitur App & Menu](#43-fitur-app--menu)
  - [4.4 Checklist Uji End-to-End](#44-checklist-uji-end-to-end)
- [5. Troubleshooting](#5-troubleshooting)
- [6. Referensi File Penting](#6-referensi-file-penting)

---

## 0. Gambaran Sistem

```
┌───────────────────────────────┐        WiFi (HTTP, port 80)        ┌────────────────────────┐
│ ESP32 DevKit V1               │ <────────────────────────────────> │ HP (app airri)         │
│  - baca sensor tiap 3 detik   │   GET /api/status, /api/logs/...   │  - Dashboard           │
│  - putuskan pompa ON/OFF      │   PUT /api/settings/...            │  - Riwayat & Statistik │
│  - simpan log & setting ke SD │   POST /api/pump/...               │  - Pemicu & Batasan    │
│  - tampilkan status di TFT    │                                    │  - cache log di SQLite │
└───────────────────────────────┘                                    └────────────────────────┘
```

- **Tidak ada server/cloud.** App bicara langsung ke IP ESP32 di jaringan
  lokal.
- ESP32 **mengambil keputusan sendiri** (otomatis). App hanya untuk
  memantau, mengatur aturan, dan uji pompa — ESP32 tetap menyiram
  walau HP tidak terhubung.
- Dua mode jaringan:
  - **AP (Access Point)** — default. ESP32 memancarkan WiFi sendiri
    (`ESP32-Irrigation`), HP connect ke situ. IP ESP32 = `192.168.4.1`.
  - **STA (Station)** — opsional. ESP32 ikut join WiFi rumah/hotspot. IP
    diberikan router (lihat di layar TFT). Bisa aktif bersamaan dengan AP.

**Urutan kerja yang disarankan:** selesaikan Bagian 2 (ESP32) sampai
verifikasi di 2.7 berhasil, baru lanjut Bagian 3 (app). Kalau ESP32 belum
jalan, app hanya akan menampilkan status *Terputus*.

---

## 1. Kebutuhan & Versi

### 1.1 Hardware

| Komponen | Catatan |
|---|---|
| ESP32 DevKit V1 (30 pin) | Board target `esp32dev` |
| Soil moisture sensor (analog) | Butuh kalibrasi (lihat 2.8) |
| AHT10 | Suhu + kelembapan udara, I2C |
| BH1750 | Intensitas cahaya (lux), I2C |
| RTC DS3231 + baterai CR2032 | Sumber waktu utama. **Baterai wajib** agar jam tidak reset |
| Modul relay 1 channel (**trigger HIGH**) + pompa air mini | Debit acuan ~200 mL/menit, selang 4×6 mm |
| TFT bundar GC9A01 240×240 | SPI |
| Modul MicroSD + kartu MicroSD | FAT32 |
| 3 LED (hijau, kuning, merah) + resistor | Indikator status |
| Kabel USB **data** | Bukan kabel yang hanya untuk charging |
| HP Android 7.0+ (atau iPhone iOS 13+) | Untuk app |

### 1.2 Software — ESP32

| Tool | Versi | Keterangan |
|---|---|---|
| PlatformIO Core | 6.x (diuji dengan **6.2.0**) | Lewat extension VSCode atau CLI |
| Platform `espressif32` | **7.0.1** (dipin di `platformio.ini`) | Didownload otomatis oleh PlatformIO saat build pertama |
| Arduino core ESP32 | **2.0.17** (ikut platform di atas) | **Harus core 2.x**, bukan 3.x |
| ArduinoJson | `^6.21.5` | **Harus v6**, v7 API-nya beda |
| Adafruit AHTX0 | `^2.0.5` | |
| Adafruit Unified Sensor | `^1.1.14` | |
| BH1750 (claws) | `^1.3.0` | |
| GFX Library for Arduino | **`1.4.9` (dipin tepat)** | Versi 1.6.x gagal compile di core 2.x |
| RTClib | `^2.1.4` | |

> 💡 **Tentang versi platform.** Versi platform sengaja dipin di
> `platformio.ini` (`platform = espressif32@7.0.1`) supaya laptop lain
> mendapat versi yang sama persis. Jangan diubah ke `espressif32` tanpa
> versi atau ke versi lain tanpa dites dulu. Jangan juga pindah ke platform
> **pioarduino** (core 3.x) kecuali siap menyesuaikan kode —
> `.vscode/extensions.json` sengaja menandai extension pioarduino sebagai
> *unwanted*.

### 1.3 Software — Mobile App

| Tool | Versi | Sumber / Keterangan |
|---|---|---|
| Flutter | **3.44.2** | Dipin di `.fvmrc` |
| Dart | 3.12.2 | Ikut Flutter 3.44.2 (`pubspec.yaml`: `sdk: ^3.12.2`) |
| FVM | versi apa saja | Pengelola versi Flutter (opsional tapi disarankan) |
| JDK | **17 atau lebih baru** | `compileOptions` & `jvmTarget` = 17. JDK bawaan Android Studio (JBR) sudah memenuhi |
| Gradle | 9.1.0 | Didownload otomatis oleh wrapper |
| Android Gradle Plugin | 9.0.1 | `android/settings.gradle.kts` |
| Kotlin | 2.3.20 | `android/settings.gradle.kts` |
| Android SDK | compileSdk/targetSdk **36**, minSdk **24** (Android 7.0) | Default Flutter 3.44.2 |
| Android NDK | 28.2.13676358 | Didownload otomatis saat build pertama |
| Xcode (khusus iOS) | Versi yang mendukung iOS SDK terbaru | Deployment target **iOS 13.0**. Plugin pakai Swift Package Manager (bukan CocoaPods) |

> ⚠️ **Kenapa versi penting:** `pubspec.lock` dan konfigurasi Gradle
> dibuat dengan Flutter 3.44.2. Flutter versi lain bisa gagal build
> (misalnya Dart SDK lebih lama dari 3.12.2 → `pub get` langsung ditolak)
> atau menghasilkan versi package berbeda.

### 1.4 Source Code

Sistem ini terdiri dari **dua repository terpisah**:

| Bagian | Repository |
|---|---|
| Firmware ESP32 | [`airri-esp32`](https://github.com/imampri100/airri-esp32) |
| Mobile app (Flutter) | [`airri-mobile`](https://github.com/imampri100/airri-mobile) |

Clone keduanya (boleh di folder mana saja, tidak harus bersebelahan):

```bash
git clone https://github.com/imampri100/airri-esp32.git
git clone https://github.com/imampri100/airri-mobile.git
```

Hasilnya dua folder: `airri-esp32/` dan `airri-mobile/`. Semua perintah di
panduan ini dijalankan dari dalam folder yang sesuai, dan semua path file
(misalnya `src/infrastructure/config/pin_config.h`) relatif terhadap root
repository masing-masing.

**Opsi:** kalau tidak memakai git, download ZIP dari GitHub (tombol
**Code → Download ZIP**) lalu extract. Hindari menaruh project di path yang
mengandung spasi atau karakter non-ASCII — beberapa tool build (terutama di
Windows) bisa gagal karenanya.

---

## 2. ESP32 (Firmware)

Repository: [`airri-esp32`](https://github.com/imampri100/airri-esp32) — semua perintah di bagian ini
dijalankan dari folder `airri-esp32/` hasil clone (lihat 1.4).

Referensi utama: [README ESP32](https://github.com/imampri100/airri-esp32/blob/main/README.md).

### 2.1 Install PlatformIO

**Opsi A — VSCode extension (disarankan)**

1. Install [VSCode](https://code.visualstudio.com/).
2. Buka tab Extensions → cari **PlatformIO IDE** (publisher: PlatformIO) →
   Install.
3. Tunggu sampai instalasi PlatformIO Core selesai (lihat notifikasi di pojok
   kanan bawah), lalu **restart VSCode**.
4. Buka folder `airri-esp32` (File → Open Folder). VSCode akan
   merekomendasikan extension PlatformIO lewat `.vscode/extensions.json`.

**Opsi B — CLI saja**

```bash
# Kalau belum pernah install PlatformIO sama sekali:
pip install -U platformio
# atau (macOS): brew install platformio

pio --version
```

> Kalau PlatformIO sudah terpasang lewat extension VSCode, CLI `pio`
> sebenarnya sudah ada, tapi **belum tentu masuk `PATH`** sehingga muncul
> `pio: command not found`. Lokasinya:
> - macOS/Linux: `~/.platformio/penv/bin` → tambahkan
>   `export PATH="$HOME/.platformio/penv/bin:$PATH"` ke `~/.zshrc` /
>   `~/.bashrc`.
> - Windows: `%USERPROFILE%\.platformio\penv\Scripts` → tambahkan ke
>   *Environment Variables → Path*.
>
> Alternatif tanpa mengubah `PATH`: buka terminal khusus PlatformIO di
> VSCode (sidebar PlatformIO → **Miscellaneous → New Terminal**).

**Kalau gagal:**

| Gejala | Solusi |
|---|---|
| Instalasi extension stuck / error Python | PlatformIO butuh Python 3. Install Python 3 dari python.org (Windows: centang *Add Python to PATH*), lalu restart VSCode |
| Ikon PlatformIO (kepala alien) tidak muncul di sidebar | Pastikan yang dibuka adalah folder berisi `platformio.ini`, bukan folder induknya |
| Konflik dengan extension C/C++ lain | Nonaktifkan `ms-vscode.cpptools-extension-pack` dan `pioarduino` (sudah ditandai *unwanted*) |

### 2.2 Rakit Hardware

Wiring lengkap: [README ESP32 → Hardware](https://github.com/imampri100/airri-esp32/blob/main/README.md#hardware).
Definisi pin di kode: `src/infrastructure/config/pin_config.h`.

| Komponen | Pin ESP32 |
|---|---|
| Soil moisture (AO) | GPIO 32 |
| AHT10, BH1750, RTC DS3231 (bus I2C bersama) | SDA = GPIO 21, SCL = GPIO 22 |
| TFT GC9A01 | CS = 33, DC = 16, RES = 17, SCK = 18, MOSI (SDA) = 23 |
| SD Card | CS = 5, SCK = 18, MOSI = 23, MISO = 19 |
| Relay pompa (IN) | GPIO 14 |
| LED hijau / kuning / merah | GPIO 25 / 26 / 27 |
| Tombol manual | GPIO 0 (tombol **BOOT** bawaan board) |

**Yang perlu diperhatikan:**

- **I2C dipakai bersama** oleh 3 modul (AHT10, BH1750, DS3231) — cukup
  paralelkan SDA ke SDA dan SCL ke SCL. Modul breakout umumnya sudah punya
  resistor pull-up, tidak perlu tambahan.
- **SPI dipakai bersama** oleh TFT dan SD Card (SCK/MOSI sama), dibedakan
  lewat pin CS masing-masing.
- **RTC DS3231**: pin `SQW` dan `32K` **dibiarkan tidak tersambung**.
  Pasang baterai CR2032 sebelum flash pertama.
- **Relay dinyalakan dengan sinyal HIGH**: firmware menulis `HIGH` ke
  GPIO 14 untuk menyalakan pompa dan `LOW` untuk mematikan
  (`pump_manager.cpp`). Pakai modul relay *high-level trigger*, atau set
  jumper trigger modul ke **H** kalau modulnya punya pilihan H/L. Dengan
  modul *low-level trigger*, logikanya terbalik: pompa menyala saat
  seharusnya mati.
- **Pompa jangan diambil dayanya dari pin 3.3V ESP32.** Beri catu daya
  sendiri lewat kontak relay (COM/NO), dan pastikan GND ESP32 dan GND
  modul relay tersambung.
- **GPIO 0 = tombol BOOT.** Menekannya saat firmware sudah jalan akan
  menyalakan/mematikan pompa (uji coba, lihat catatan di 4.3). Menahannya saat reset/upload akan
  masuk mode flashing — jangan pasang tombol eksternal di GPIO 0 yang
  tertekan terus.
- **GPIO 16/17** di board ini adalah RX2/TX2 — sudah dipakai untuk TFT,
  jangan dipakai untuk Serial2.

**Opsi:** kalau pakai tombol eksternal atau pin lain, ubah di
`pin_config.h` lalu upload ulang.

### 2.3 Siapkan SD Card

SD Card menyimpan **setting** (WiFi, pemicu, batasan, bahasa) dan **log**
(sensor & irigasi). Tanpa SD Card, device tetap jalan tapi setting tidak
tersimpan dan log tidak tercatat.

**Format:**

- Filesystem **FAT32**.
- Kartu ≤ 32 GB (SDHC) paling aman. Kartu 64 GB+ (SDXC) biasanya
  diformat exFAT dari pabrik — harus diformat ulang ke FAT32:
  - macOS: Disk Utility → Erase → Format **MS-DOS (FAT)**, Scheme
    **Master Boot Record**.
  - Windows: menu Format bawaan hanya menawarkan FAT32 untuk kartu ≤ 32 GB.
    Untuk kartu lebih besar pakai tool pihak ketiga seperti *FAT32 Format
    (guiformat)*.
  - Linux: `sudo mkfs.vfat -F 32 /dev/sdX1` (pastikan device-nya benar).

**Struktur yang dibuat otomatis oleh firmware saat boot** (hanya dibuat
kalau belum ada; khusus `trigger.json` & `restriction.json`, field yang
belum ada juga dilengkapi — lihat 2.4):

```
/settings/wifi.json         → kredensial & toggle AP/STA
/settings/trigger.json      → aturan pemicu
/settings/restriction.json  → aturan batasan
/settings/language.json     → bahasa TFT & decision.reason ("id"/"en")
/metadata/sync.json         → metadata sinkronisasi
/logs/sensor/YYYY-MM.ndjson       → log sensor (1 file per bulan)
/logs/irrigation/YYYY-MM.ndjson   → log penyiraman
```

Detail format log & rotasi: [docs/storage.md](https://github.com/imampri100/airri-esp32/blob/main/docs/storage.md).

**Pilih salah satu opsi:**

| Opsi | Cara | Cocok untuk |
|---|---|---|
| **A. Kartu kosong** (paling simpel) | Format FAT32, langsung pasang | Pemakaian normal. Device jadi AP `ESP32-Irrigation` / `12345678` |
| **B. Isi manual** | Format, buat `/settings/wifi.json` sendiri (contoh di bawah) | Ganti SSID/password AP, atau pakai mode STA |

**Contoh `wifi.json` (opsi B):**

```json
{"apSsid": "ESP32-Irrigation", "apPassword": "12345678", "staSsid": "", "staPassword": "", "apEnabled": true, "staEnabled": false}
```

| Field | Arti |
|---|---|
| `apSsid` / `apPassword` | Nama & password WiFi yang dipancarkan ESP32. Password **minimal 8 karakter**. Kosong → pakai default dari `wifi_config.h` |
| `staSsid` / `staPassword` | WiFi rumah/hotspot yang ingin di-join ESP32 (opsional) |
| `apEnabled` | `true` = ESP32 memancarkan WiFi sendiri. Default `true` |
| `staEnabled` | `true` = ESP32 mencoba join WiFi `staSsid`. Default `false` |

**Yang perlu diperhatikan:**

- Kalau memakai SD Card bekas dari alat lain, cek dulu isi
  `/settings/wifi.json` dan `/settings/language.json`-nya — setting lama
  (misalnya `apEnabled: false`) akan tetap dipakai.
- Kalau `apEnabled` dan `staEnabled` sama-sama `false`, firmware otomatis
  memaksa AP tetap menyala (fail-safe) supaya device tidak terkunci.
- Kalau `staEnabled: true` tapi WiFi-nya tidak terjangkau, AP bisa
  **kedip-kedip/hilang** saat discan HP (ESP32 hanya punya 1 radio). Set
  `staEnabled: false` kalau STA tidak dipakai.
- Kalau ada 2 alat berdekatan, bedakan `apSsid`-nya.
- Setelah edit file di laptop, **eject** kartu dengan benar sebelum dicabut,
  lalu restart ESP32 (tombol EN/RST atau cabut-colok power).
- Re-flash firmware **tidak** menghapus isi SD Card.

### 2.4 Konfigurasi di Kode (Opsional)

Semua ini **boleh dilewati** untuk percobaan pertama. Setiap perubahan di
sini butuh build & upload ulang.

| File | Konstanta | Default | Kapan diubah |
|---|---|---|---|
| `src/infrastructure/config/wifi_config.h` | `DEFAULT_AP_SSID`, `DEFAULT_AP_PASSWORD` | `ESP32-Irrigation` / `12345678` | Kalau malas edit SD Card. SD Card selalu menang kalau diisi |
| | `DEFAULT_STA_SSID`, `DEFAULT_STA_PASSWORD` | dummy | Fallback STA kalau `staSsid` di SD kosong |
| | `HTTP_PORT` | `80` | Jarang perlu. Kalau diubah, alamat di app jadi `http://IP:PORT` |
| `src/infrastructure/hardware/sensor_manager.h` | `SOIL_ADC_DRY`, `SOIL_ADC_WET` | `3000` / `1200` | Setelah kalibrasi (lihat 2.8) |
| `src/infrastructure/config/pump_config.h` | `FLOW_RATE_ML_PER_MINUTE` | `200.0` | Kalau ganti pompa. Dipakai untuk estimasi volume air di log |
| `src/infrastructure/config/pin_config.h` | semua pin | lihat 2.2 | Kalau wiring berbeda |

Setting yang **tidak perlu** diubah di kode karena bisa diatur dari app:

| Setting | Default |
|---|---|
| Pemicu | soil moisture `<=` 30% |
| Batasan kelembapan udara | **nonaktif** (nilai awal kalau diaktifkan: `>=` 80%) |
| Batasan suhu udara | **nonaktif** (nilai awal kalau diaktifkan: `>=` 35 °C) |
| Batasan cahaya | **nonaktif** (nilai awal kalau diaktifkan: `<=` 100 lux) |
| `maxPumpRuntimeSecond` | 15 detik |

Jadi pada alat yang belum pernah diatur, pompa hanya ditentukan oleh
pemicu dan batas nyala 15 detik.

> 💡 Nilai default ini ada di kode (`trigger_setting.h`,
> `restriction_setting.h`). Saat boot, firmware menulis `trigger.json` dan
> `restriction.json` di SD Card **lengkap dengan nilai default** kalau
> filenya belum ada atau ada field yang belum terisi (misalnya file lama
> berisi `{}`). Jadi isi setting aktif selalu bisa dilihat langsung di SD
> Card. File yang rusak (JSON tidak valid) sengaja tidak ditimpa.

### 2.5 Build

**VSCode:** sidebar PlatformIO → **esp32dev → General → Build**
(atau ikon ✓ di status bar bawah).

**CLI:**

```bash
cd airri-esp32
pio run
```

**Yang perlu diperhatikan:**

- Build pertama butuh **internet** dan bisa lama (5–15 menit) karena
  mendownload toolchain, framework, dan library. Build berikutnya jauh
  lebih cepat.
- Berhasil kalau di akhir muncul `[SUCCESS]`, disertai ringkasan RAM/Flash.

**Kalau gagal:**

| Error | Penyebab & Solusi |
|---|---|
| `esp32-hal-periman.h: No such file or directory` | GFX Library ter-update ke 1.6.x. Pastikan `platformio.ini` tetap `moononournation/GFX Library for Arduino @ 1.4.9`, lalu hapus folder `.pio/libdeps` dan build ulang |
| Error terkait `ArduinoJson` (`JsonDocument` abstract, `DynamicJsonDocument` deprecated) | ArduinoJson v7 terpasang. Pastikan tetap `^6.21.5`, hapus `.pio/libdeps`, build ulang |
| Error C++17 (`std::optional`, structured binding, dsb.) | Pastikan `build_flags` masih berisi `-std=gnu++17` dan `build_unflags` berisi `-std=gnu++11` |
| `HTTPClientError` / gagal download package | Masalah jaringan. Coba ulang, ganti koneksi, atau matikan VPN/proxy |
| Error aneh setelah ganti versi apa pun | Bersihkan cache: `pio run --target clean`, atau hapus folder `.pio/` seluruhnya lalu build ulang |

### 2.6 Upload ke ESP32

**Sebelum upload:**

1. **Pastikan jam laptop sudah WIB dan akurat.** Kalau RTC baru atau
   baterainya pernah habis, firmware menyetel jam RTC dari waktu
   kompilasi (jam laptop). Jam laptop salah → timestamp log salah.
2. **Tutup Serial Monitor** yang sedang terbuka — port hanya bisa dipakai
   satu program.
3. Colok ESP32 via USB. Cek port terdeteksi:
   ```bash
   pio device list
   # macOS  : /dev/cu.usbserial-XXXX, /dev/cu.SLAB_USBtoUART, /dev/cu.wchusbserialXXXX
   # Windows: COM3, COM4, ... (lihat juga Device Manager → Ports)
   # Linux  : /dev/ttyUSB0 atau /dev/ttyACM0
   ```

**Upload:**

- **VSCode:** **esp32dev → General → Upload** (atau ikon → di status bar).
- **CLI:**
  ```bash
  pio run --target upload
  ```

**Opsi:**

- Kalau ada beberapa port, tentukan secara manual:
  ```bash
  pio run --target upload --upload-port /dev/cu.usbserial-0001   # Windows: --upload-port COM3
  ```
  atau tambahkan `upload_port = <port>` di `platformio.ini`.
- Upload + langsung buka monitor: `pio run --target upload --target monitor`.

**Kalau gagal:**

| Gejala | Solusi |
|---|---|
| Stuck di `Connecting........_____` lalu `Failed to connect` | **Tahan tombol BOOT** saat muncul `Connecting...`, lepas setelah progres `Writing at ...` mulai jalan |
| Port tidak muncul sama sekali | 1) Ganti kabel USB (banyak kabel hanya untuk charge). 2) Install driver USB-serial sesuai chip di board: **CP210x** (Silicon Labs) atau **CH340/CH9102** (WCH). 3) Coba port USB lain / tanpa hub |
| `Resource busy` / `could not open port` / `Access is denied` | Serial Monitor (VSCode, Arduino IDE, `screen`) masih terbuka — tutup dulu |
| Linux: `Permission denied: '/dev/ttyUSB0'` | Tambahkan user ke grup serial: `sudo usermod -aG dialout $USER`, lalu logout/login |
| `A fatal error occurred: ... packet header` | Turunkan kecepatan upload: tambah `upload_speed = 115200` di `platformio.ini` |
| Upload sukses tapi board restart terus (brownout) | Daya USB kurang. Pakai port USB langsung (bukan hub), atau jangan jalankan pompa dari daya USB yang sama |

### 2.7 Serial Monitor & Verifikasi

**Buka Serial Monitor** (baud **115200**, sudah diset di `platformio.ini`):

- VSCode: **esp32dev → General → Monitor** (ikon 🔌 di status bar).
- CLI: `pio device monitor` (keluar dengan `Ctrl+C`).

Tekan tombol **EN/RST** di board untuk melihat log sejak boot.

**Log yang diharapkan (kurang lebih):**

```
Smart Irrigation - booting...
/settings/wifi.json belum diisi apSsid - pakai default AP dari wifi_config.h (ESP32-Irrigation).
    ↑ atau "Kredensial Access Point dimuat dari SD Card (<ssid>)" kalau apSsid diisi
Access Point aktif - SSID: ESP32-Irrigation, IP: 192.168.4.1 -- pakai ini sebagai base_url, ...
RTC siap. Unix timestamp sekarang: 17xxxxxxxx
HTTP server aktif di port 80
Setup selesai
```

**Cek fisik:**

| Indikator | Kondisi normal |
|---|---|
| Layar TFT | Jam `HH:MM:SS WIB`, baris `AP 192.168.4.1`, nilai Suhu/Lembap/Cahaya/Tanah, Pompa ON/OFF, dan status |
| Status TFT sebelum HP connect | `Menunggu HP connect...` |
| LED | Kuning berkedip (menunggu HP), hijau setelah HP connect |
| WiFi | SSID `ESP32-Irrigation` muncul di daftar WiFi HP/laptop |

**Arti LED & status TFT (urutan prioritas):**

| LED | Status TFT | Arti |
|---|---|---|
| Merah berkedip | `ERROR: Waktu blm sinkron` | RTC gagal & NTP belum berhasil. Log akan bertimestamp 0 — **harus diperbaiki** |
| Kuning menyala | `Menyiram...` | Pompa sedang menyala |
| Kuning berkedip | `Menunggu HP connect...` / `Menunggu WiFi Station...` | Device siap tapi belum ada yang terhubung |
| Hijau | `Siap - <IP>` | Normal |

**Cek API cepat** — connect laptop ke WiFi `ESP32-Irrigation`, lalu:

```bash
curl http://192.168.4.1/api/ping      # → {"pong":true}
curl http://192.168.4.1/api/status    # → JSON sensor, keputusan, status pompa
```

Atau buka `http://192.168.4.1/api/status` di browser.

**Kalau gagal:**

| Gejala / log | Solusi |
|---|---|
| Monitor menampilkan karakter acak | Baud rate salah — harus 115200 |
| `SD Card gagal diinisialisasi` | Kartu belum FAT32 / tidak terpasang rapat / wiring SPI (CS=5, SCK=18, MOSI=23, MISO=19) salah / modul SD butuh 5V (cek spesifikasi modul) |
| `RTC DS3231 tidak terdeteksi di bus I2C` / `RTC DS3231 tidak siap - mencoba fallback NTP` | Cek wiring I2C (21/22), VCC 3.3V & GND. Jika tidak bisa, sambungkan STA ke WiFi ber-internet supaya fallback NTP bekerja |
| `RTC DS3231 kehilangan daya` / tahun di log aneh | Baterai CR2032 habis/tidak terpasang. Pasang baterai, lalu upload ulang firmware supaya RTC disetel dari jam laptop |
| `AHT10 tidak terdeteksi di bus I2C` / `BH1750 tidak terdeteksi di bus I2C`, nilai sensor 0 | Cek wiring I2C (SDA 21, SCL 22), VCC & GND modul |
| TFT blank / putih | Cek wiring CS=33, DC=16, RES=17, dan VCC/GND/BL. Firmware tetap jalan walau TFT mati — cek via Serial/API |
| Teks di TFT terpotong pinggir | Posisi baris dihitung secara geometri, bukan diukur di hardware — sesuaikan `y`/`lineHeight` di `display_manager.cpp` |
| SSID tidak muncul | Cek `apEnabled` di `wifi.json`. Kalau `staEnabled: true` tapi WiFi tujuan tidak ada, set `false` |

### 2.8 Kalibrasi Soil Moisture

Setiap sensor soil moisture punya rentang ADC berbeda, jadi persentase
kelembapan tanah **tidak akurat** sebelum dikalibrasi.

Firmware **tidak** menampilkan nilai ADC mentah (Serial, TFT, dan API
hanya menampilkan persentase), jadi untuk kalibrasi perlu print sementara:

1. Di `src/infrastructure/hardware/sensor_manager.cpp`, fungsi
   `readSoilMoisture()`, tambahkan satu baris setelah `analogRead`:
   ```cpp
   int raw = analogRead(PinConfig::SOIL_SENSOR);
   Serial.printf("soil raw ADC = %d\n", raw);   // sementara, untuk kalibrasi
   ```
2. Build & upload, lalu buka Serial Monitor. Nilai muncul setiap sensor
   dibaca (tiap 3 detik, ditambah tiap refresh layar).
3. Biarkan sensor **di udara (kering)** → catat nilai ADC-nya.
4. Celupkan sensor ke **air** (sampai batas garis maksimum di sensor) →
   catat nilai ADC-nya.
5. Isi kedua nilai itu ke `SOIL_ADC_DRY` dan `SOIL_ADC_WET` di
   `src/infrastructure/hardware/sensor_manager.h`, **hapus** baris
   `Serial.printf` tadi, lalu build & upload ulang.

**Perhatikan:** sensor kapasitif nilainya *turun* saat basah (DRY > WET).
Kalau hasil persentase terbalik, kemungkinan kedua nilai tertukar.

### 2.9 Uji API tanpa App (Opsional)

Berguna untuk memastikan firmware benar sebelum menyalahkan app.

1. Import [docs/smart-irrigation-api_postman_collection.json](https://github.com/imampri100/airri-esp32/blob/main/docs/smart-irrigation-api_postman_collection.json) ke Postman.
2. Connect laptop ke WiFi ESP32.
3. Untuk request `PUT`/`POST` yang ada body: **Body → raw → JSON**.
4. Mulai dari `GET /api/status`.

Daftar endpoint lengkap: [README ESP32 → REST API](https://github.com/imampri100/airri-esp32/blob/main/README.md#rest-api).

> ⚠️ `POST /api/pump/test` bersifat **blocking** (maks 10 detik) —
> jangan kirim request lain selama test berjalan.

---

## 3. Mobile App (Flutter)

Repository: [`airri-mobile`](https://github.com/imampri100/airri-mobile) — semua perintah di bagian ini
dijalankan dari folder `airri-mobile/` hasil clone (lihat 1.4).

Referensi utama: [README mobile app](README.md).

### 3.1 Install Flutter & Tools

**Opsi A — dengan FVM (disarankan)**

```bash
# 1) install FVM kalau belum ada — pilih salah satu:
brew tap leoafarias/fvm && brew install fvm   # macOS
choco install fvm                             # Windows (Chocolatey)
dart pub global activate fvm                  # semua OS, kalau Dart sudah terpasang

# 2) install Flutter sesuai versi project
cd airri-mobile
fvm install          # membaca .fvmrc → install Flutter 3.44.2
fvm flutter --version
```

Semua perintah Flutter dijalankan dengan prefix `fvm`, misalnya
`fvm flutter run`.

**Opsi B — tanpa FVM**

Install Flutter **3.44.2** secara manual dari
[arsip rilis Flutter](https://docs.flutter.dev/release/archive), tambahkan
ke `PATH`, lalu jalankan perintah tanpa prefix `fvm`. Pastikan
`flutter --version` menunjukkan 3.44.2.

**Android:**

1. Install **Android Studio**.
2. Buka Android Studio → **SDK Manager**:
   - *SDK Platforms*: centang **Android 16 (API 36)**.
   - *SDK Tools*: centang **Android SDK Command-line Tools**,
     **Android SDK Platform-Tools**, **Android SDK Build-Tools**.
   - NDK tidak perlu dicentang manual — Gradle akan mendownload versi yang
     dibutuhkan (28.2.13676358) otomatis.
3. Setujui lisensi:
   ```bash
   fvm flutter doctor --android-licenses
   ```

**JDK:**

- Butuh **JDK 17 atau lebih baru**. Flutter secara default memakai JDK
  bawaan Android Studio (JBR), yang sudah memenuhi.
- Kalau Flutter ternyata memakai JDK lain (misalnya JDK 11 → build
  gagal), cek & ubah dengan:
  ```bash
  fvm flutter config --list                         # lihat jdk-dir
  fvm flutter config --jdk-dir "/path/ke/jdk-17"    # ganti
  fvm flutter config --jdk-dir ""                   # kembali ke JDK Android Studio
  ```
- `java -version` di terminal **belum tentu** sama dengan JDK yang dipakai
  Flutter. Yang dipakai Flutter terlihat di `fvm flutter doctor -v`, bagian
  *Android toolchain → Java binary at*.

**iOS (opsional, macOS saja):**

1. Install **Xcode** dari App Store, buka sekali untuk menyelesaikan
   instalasi komponen.
2. `sudo xcodebuild -runFirstLaunch`
3. Tidak perlu CocoaPods — project ini memakai Swift Package Manager.

**Verifikasi:**

```bash
fvm flutter doctor -v
```

Pastikan bagian **Flutter**, **Android toolchain**, dan (kalau perlu)
**Xcode** bertanda ✓. Peringatan untuk Chrome/Linux/Windows/VS bisa
diabaikan.

**Opsi editor:**

Kalau pakai FVM, jalankan sekali di folder project:

```bash
fvm use 3.44.2
```

FVM akan membuat link ke SDK Flutter di folder `.fvm/` project (folder ini
di-*ignore* git, jadi dibuat ulang di tiap komputer) dan, untuk VSCode,
otomatis mengisi `dart.flutterSdkPath` di `.vscode/settings.json`.

- **VSCode:** install extension *Flutter*. Setelah `fvm use`, restart
  VSCode — status bar bawah harus menunjukkan Flutter 3.44.2.
- **Android Studio:** Settings → Languages & Frameworks → Flutter →
  Flutter SDK path → arahkan ke `.fvm/flutter_sdk` di dalam folder project.
  Kalau link itu tidak ada, pakai lokasi cache FVM (lihat dengan
  `fvm list`), misalnya `~/fvm/versions/3.44.2` di macOS/Linux.

### 3.2 Ambil Dependency

```bash
fvm flutter pub get
```

**Perhatikan:**

- File `injection.config.dart` (hasil generate `injectable`) **sudah ada**
  di repo, jadi tidak perlu menjalankan `build_runner` untuk sekadar
  menjalankan app.
- `build_runner` hanya perlu dijalankan kalau mengubah anotasi DI
  (`@injectable`, `@module`, dll.):
  ```bash
  fvm dart run build_runner build --delete-conflicting-outputs
  ```

**Kalau gagal:**

| Error | Solusi |
|---|---|
| `The current Dart SDK version is X. Because airri_mobile requires SDK version ^3.12.2...` | Flutter yang terpakai bukan 3.44.2. Pakai `fvm flutter`, bukan `flutter` |
| Gagal resolve versi package | Jangan hapus `pubspec.lock`. Jalankan `fvm flutter clean && fvm flutter pub get` |
| Error jaringan saat download package | Cek internet / proxy. Coba ulang |

### 3.3 Siapkan Device Target

**Opsi A — HP Android fisik via USB (disarankan)**

1. Aktifkan **Developer options**: Settings → About phone → ketuk **Build
   number** 7 kali.
2. Aktifkan **USB debugging** di Developer options.
3. Colok HP ke laptop → izinkan dialog *"Allow USB debugging?"* di HP.
4. Cek:
   ```bash
   fvm flutter devices
   ```

**Opsi B — Android via WiFi (wireless debugging, Android 11+)**

Berguna karena nanti HP harus pindah ke WiFi ESP32. Namun **perhatikan:**
begitu HP connect ke WiFi ESP32, koneksi debug ke laptop putus (kecuali
laptop juga di WiFi ESP32). Untuk pengujian dengan ESP32, lebih praktis
pakai USB atau install APK (3.5–3.6).

**Opsi C — Emulator Android**

- Buat emulator di Android Studio → Device Manager (API 24+).
- Emulator memakai jaringan laptop. Supaya bisa menjangkau
  `192.168.4.1`, **laptop** yang harus connect ke WiFi ESP32 (laptop akan
  kehilangan internet selama itu).

**Opsi D — iPhone**

- Buka `ios/Runner.xcworkspace` di Xcode → target **Runner** → **Signing
  & Capabilities** → pilih *Team* (Apple ID gratis bisa, app berlaku 7
  hari).
- Di iPhone: aktifkan **Developer Mode** (Settings → Privacy & Security),
  dan percayai sertifikat developer (Settings → General → VPN & Device
  Management).

### 3.4 Jalankan App (Mode Development)

```bash
fvm flutter run                     # pilih device kalau lebih dari satu
fvm flutter run -d <device-id>      # langsung ke device tertentu
```

Saat app berjalan di terminal:

| Tombol | Fungsi |
|---|---|
| `r` | Hot reload (perubahan UI langsung terlihat) |
| `R` | Hot restart (state di-reset) |
| `q` | Keluar |

**Opsi mode:**

| Mode | Perintah | Keterangan |
|---|---|---|
| Debug | `fvm flutter run` | Bisa hot reload, performa lebih lambat, ada banner DEBUG |
| Profile | `fvm flutter run --profile` | Mengukur performa |
| Release | `fvm flutter run --release` | Performa maksimal, tanpa hot reload — paling mirip kondisi nyata |

**Kalau gagal:**

| Error | Solusi |
|---|---|
| `No supported devices connected` | USB debugging belum aktif / belum di-*allow* / kabel charge-only. Cek `adb devices` |
| `Unsupported class file major version` / error Java | JDK tidak cocok. Pastikan JDK 17+ lewat `fvm flutter config --jdk-dir` |
| `flutter.sdk not set in local.properties` | Jalankan `fvm flutter pub get` / `fvm flutter run` dari **root project** (bukan dari folder `android/`) — file `android/local.properties` dibuat otomatis |
| `SDK location not found` | Set `ANDROID_HOME` atau `fvm flutter config --android-sdk <path>`. Lokasi default Android SDK: macOS `~/Library/Android/sdk`, Windows `%LOCALAPPDATA%\Android\Sdk`, Linux `~/Android/Sdk` |
| NDK error / `NDK did not have a source.properties` | Hapus folder NDK yang rusak di `<Android SDK>/ndk/<versi>`, build ulang (akan didownload ulang) |
| Gradle build lama/gagal karena memori | `android/gradle.properties` sudah diset `-Xmx8G`. Kalau RAM laptop kecil, turunkan ke `-Xmx4G` |
| Error aneh setelah ganti versi/branch | `fvm flutter clean && fvm flutter pub get`, lalu run ulang |

### 3.5 Build APK / IPA

**APK Android (paling umum):**

```bash
fvm flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

**Opsi:**

```bash
# APK per arsitektur (ukuran lebih kecil). Kebanyakan HP modern pakai arm64-v8a
fvm flutter build apk --release --split-per-abi

# App Bundle (hanya untuk upload ke Play Store)
fvm flutter build appbundle --release
```

**Perhatikan:**

- Build release saat ini **ditandatangani dengan debug key**
  (`android/app/build.gradle.kts`). Cukup untuk demo/sidang dan install
  manual, **tidak bisa** diupload ke Play Store. Untuk Play Store perlu
  membuat keystore sendiri.
- Kalau sebelumnya sudah terinstall APK dari laptop lain (debug key
  berbeda), install akan gagal dengan *signature conflict* — uninstall
  app lama dulu.

**iOS:**

```bash
fvm flutter build ipa --release
```

Membutuhkan akun Apple Developer berbayar untuk distribusi. Untuk sekadar
mencoba di iPhone sendiri, cukup `fvm flutter run --release` dengan device
tersambung (lihat 3.3 Opsi D).

### 3.6 Install APK ke HP

**Opsi A — via kabel (adb):**

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
# atau
fvm flutter install
```

**Opsi B — tanpa kabel:** kirim file `app-release.apk` ke HP (Google Drive,
Telegram, AirDrop ke Android tidak bisa → pakai Drive/Telegram), buka di
HP, izinkan **Install unknown apps** untuk aplikasi yang dipakai membuka
file tersebut.

**Kalau gagal:**

| Gejala | Solusi |
|---|---|
| *App not installed* / *package conflicts* | Uninstall app airri lama dulu (signature berbeda) |
| *There was a problem parsing the package* | APK split tidak cocok arsitektur HP — pakai APK universal (`build apk --release` tanpa `--split-per-abi`) |
| Diblokir Play Protect | Pilih **Install anyway** |
| HP Android < 7.0 | Tidak didukung (minSdk 24) |

---

## 4. Menghubungkan App ke ESP32

### 4.1 Connect HP ke WiFi ESP32

1. Pastikan ESP32 sudah menyala dan SSID-nya terlihat (lihat 2.7).
2. HP → Settings → WiFi → pilih `ESP32-Irrigation` → password `12345678`
   (atau sesuai `wifi.json`).

**Perhatikan (Android):**

- Akan muncul notifikasi *"WiFi ini tidak memiliki akses internet"* —
  pilih **Tetap terhubung / Keep WiFi connection**. Jika tidak, Android
  bisa otomatis pindah ke WiFi lain.
- **Matikan data seluler** kalau app gagal konek. Beberapa HP (Samsung,
  Xiaomi, dll.) mengarahkan traffic ke data seluler saat WiFi tidak punya
  internet. Nonaktifkan juga fitur seperti *Switch to mobile data* /
  *Adaptive Wi-Fi* / *WLAN+*.
- Matikan **VPN** atau **Private DNS** yang memaksa semua traffic lewat
  internet.

**Perhatikan (iOS):**

- Saat pertama kali app mencoba konek, iOS bisa menampilkan dialog izin
  **Local Network** — pilih **Allow**. Kalau terlanjur ditolak: Settings →
  Privacy & Security → Local Network → aktifkan airri.

### 4.2 Atur Alamat Perangkat

App menyimpan alamat ESP32 di HP (default `http://192.168.4.1`).

| Mode ESP32 | Alamat di app | Kondisi HP |
|---|---|---|
| AP (default) | `http://192.168.4.1` — **tidak perlu diubah** | Connect ke WiFi `ESP32-Irrigation` |
| STA | `http://<IP STA di layar TFT>`, misalnya `http://192.168.1.42` | Connect ke WiFi/hotspot **yang sama** dengan ESP32 |

Cara ubah: menu **⋮** (pojok kanan atas) → **📡 Alamat Perangkat** →
isi alamat lengkap dengan `http://` → simpan.

**Perhatikan:**

- Tulis dengan `http://`, **bukan** `https://`. Garis miring di akhir
  (`/`) otomatis dihapus.
- Mengosongkan isian akan mengembalikan ke default `http://192.168.4.1`.
- **Mode STA:** IP dari router bisa berubah setelah ESP32 restart. Cek
  lagi baris `STA` di TFT kalau tiba-tiba *Terputus*. Kalau pakai router
  sendiri, bisa set *DHCP reservation* supaya IP tetap.
- Kalau mode STA pakai **hotspot HP**, maka HP yang menjalankan app bisa
  sekaligus menjadi hotspot-nya — ESP32 dan HP otomatis satu jaringan,
  dan HP tetap punya internet.

**Indikator koneksi:** di app ada status *Menghubungkan... / Terhubung /
Terputus*. App mengecek koneksi tiap **15 detik**, dengan batas waktu
koneksi **8 detik** per request — jadi setelah ganti WiFi/alamat, beri
jeda beberapa detik sebelum menyimpulkan gagal.

### 4.3 Fitur App & Menu

**Tab navigasi bawah:**

| Tab | Fungsi |
|---|---|
| **Dashboard** | Data sensor (tanah, kelembapan & suhu udara, cahaya), status pompa, hasil evaluasi pemicu/batasan beserta alasan keputusan, ringkasan hari ini, dan tombol **▷ Uji Pompa** (menyalakan pompa 3 detik lalu mati otomatis, tidak dicatat di Riwayat). Banner peringatan muncul kalau waktu device belum sinkron. Data diambil saat halaman dibuka — **tidak update otomatis**, tarik layar ke bawah untuk refresh |
| **Riwayat** | Log sensor & irigasi yang disinkronkan dari ESP32 ke database lokal HP. **Sinkronisasi terjadi saat tab ini dibuka atau ditarik ke bawah.** Mendeteksi *gap* (data yang hilang di device sebelum sempat disinkronkan) |
| **Statistik** | Grafik tren kelembapan tanah & pemakaian air: 7 Hari, 30 Hari, 1 Tahun, 3 Tahun, Semua. Dihitung dari data lokal — buka **Riwayat** dulu supaya data terbaru ikut tersinkron |
| **Pemicu** | Kondisi soil moisture yang menyalakan pompa (misalnya `<= 30%`) |
| **Batasan** | Kondisi yang **mencegah** pompa menyala walau pemicu terpenuhi (suhu, kelembapan udara, cahaya — masing-masing bisa on/off) + batas maksimal nyala pompa (detik) |

**Menu ⋮:**

| Menu | Fungsi |
|---|---|
| ⓘ Tentang Perangkat | Nama & versi app, serta alamat ESP32 yang sedang dipakai |
| 🗑️ Hapus Log | Menghapus semua log sensor & irigasi di ESP32 **dan** cache lokal di HP. Setting tidak berubah |
| 📡 Alamat Perangkat | Mengubah alamat ESP32 (lihat 4.2) |
| 🪵 Log Permintaan | Mencetak request/response HTTP ke console (untuk debug saat `flutter run`). Default nonaktif |
| 🌐 Language / Bahasa | Ganti bahasa app Indonesia ↔ Inggris. Sekaligus mengirim bahasa yang sama ke ESP32 (layar TFT & alasan keputusan) kalau device sedang terhubung |
| ↻ Reset Pabrik | Mengembalikan **pemicu dan batasan** ke default, lalu menghapus semua log di ESP32 dan cache lokal di HP. Setting WiFi (`wifi.json`) dan bahasa **tidak** ikut direset. Tidak bisa dibatalkan |

Bahasa app default **Indonesia** (tidak mengikuti bahasa HP) — ganti lewat menu 🌐.

> 💡 **Tentang menyalakan pompa manual.** Firmware mengevaluasi pemicu
> & batasan setiap **3 detik** dan mematikan pompa kalau keputusannya
> "tidak menyiram". Akibatnya:
> - **▷ Uji Pompa** di app (`POST /api/pump/test`) selalu berjalan penuh
>   selama durasinya, karena firmware sibuk menunggu selama tes. Selama
>   itu **layar TFT dan LED tidak berubah** (tetap `Pompa: OFF`), dan tes
>   ini tidak dicatat di Riwayat.
> - **Tombol BOOT** di board dan `POST /api/pump/start` hanya membuat
>   pompa menyala sebentar: kalau pemicu tidak terpenuhi, pompa dimatikan
>   lagi oleh firmware dalam ≤ 3 detik dan dianggap uji coba (tidak
>   dicatat di Riwayat). Kalau pemicu terpenuhi, pompa lanjut menyala
>   seperti penyiraman otomatis: tercatat di Riwayat dan tetap kena batas
>   `maxPumpRuntimeSecond`.
> - Untuk menyiram lebih lama secara sengaja, ubah **Pemicu** (misalnya
>   jadi `<= 100%`), lalu kembalikan setelahnya.

### 4.4 Checklist Uji End-to-End

Cocok dipakai sebelum demo/sidang:

- [ ] ESP32 menyala, TFT menampilkan jam yang benar & nilai sensor masuk akal
- [ ] Serial Monitor: tidak ada error SD Card / RTC
- [ ] HP terhubung ke WiFi ESP32, data seluler mati
- [ ] App menunjukkan status **Terhubung**, TFT berubah ke `Siap - <IP>`, LED hijau
- [ ] Tarik Dashboard ke bawah → nilai sensor sama dengan yang tampil di TFT
- [ ] Tekan **▷ Uji Pompa** di Dashboard → relay klik, pompa menyala 3 detik lalu mati sendiri, muncul notifikasi *Test pump selesai* (layar TFT & LED memang tidak berubah selama tes)
- [ ] Saat penyiraman otomatis berjalan → pompa menyala bersamaan dengan TFT `Pompa: ON` / `Menyiram...` dan LED kuning menyala terus
- [ ] Ubah **Pemicu** (misalnya jadi `<= 90%`) → pompa menyala otomatis saat sensor di tanah kering; kembalikan setelahnya
- [ ] Ubah **Pemicu** jadi `<= 100%` → pompa menyala, dipaksa mati setelah `maxPumpRuntimeSecond` (safety timeout), lalu menyala lagi ± 3 detik kemudian selama pemicu masih terpenuhi. Kembalikan pemicu setelahnya
- [ ] Ganti bahasa lewat menu 🌐 → app dan layar TFT ikut berganti bahasa
- [ ] Buka **Riwayat** → log baru muncul setelah sinkron
- [ ] Buka **Statistik** (setelah Riwayat tersinkron) → grafik tampil
- [ ] Restart ESP32 → setting tetap sama (tersimpan di SD Card), jam tetap benar (RTC)

---

## 5. Troubleshooting

Ringkasan masalah yang paling sering, di luar tabel di tiap langkah.

| Masalah | Kemungkinan penyebab | Solusi |
|---|---|---|
| App selalu **Terputus** | HP tidak di WiFi ESP32 / data seluler dipakai / alamat salah | Buka `http://192.168.4.1/api/ping` di browser HP. Kalau browser juga gagal → masalah jaringan (4.1). Kalau browser berhasil tapi app gagal → cek alamat di 📡 Alamat Perangkat |
| App kadang terhubung, kadang terputus | Sinyal lemah / AP terganggu percobaan STA | Dekatkan HP. Set `staEnabled: false` kalau STA tidak dipakai |
| Banner "waktu belum sinkron" di app | RTC tidak terdeteksi / baterai habis | Lihat 2.7 bagian RTC |
| Riwayat kosong | Log belum ada / belum sinkron / SD Card gagal | Log sensor ditulis tiap 3 detik — tarik tab Riwayat ke bawah untuk sinkron ulang. Cek Serial untuk error SD |
| Riwayat menandai *gap* | Log di device sudah terhapus (retensi / Hapus Log) sebelum sempat disinkronkan HP | Normal — itu memang fitur deteksi data hilang |
| Pompa tidak pernah menyala otomatis | Pemicu belum terpenuhi / terhalang Batasan | Lihat bagian evaluasi kondisi di Dashboard (ada alasan keputusan) |
| Pompa mati sendiri setelah ±15 detik, lalu nyala lagi | Safety timeout `maxPumpRuntimeSecond`. Kalau pemicu masih terpenuhi, pompa dinyalakan lagi di evaluasi berikutnya (±3 detik) | Normal. Ubah batasnya di tab **Batasan** kalau perlu |
| Pompa dari tombol BOOT langsung mati lagi | Firmware mematikan pompa tiap 3 detik kalau pemicu tidak terpenuhi | Normal — lihat catatan di 4.3 |
| Dashboard tidak berubah | Dashboard tidak update otomatis | Tarik layar ke bawah untuk refresh |
| Statistik / ringkasan hari ini tidak update | Keduanya dihitung dari data lokal di HP | Buka tab **Riwayat** (atau tarik ke bawah) supaya log tersinkron |
| Pompa menyala terus saat boot / nyala-mati terbalik | Modul relay *low-level trigger*, padahal firmware menyalakan relay dengan `HIGH` | Pakai modul *high-level trigger* atau set jumper trigger ke **H** (lihat 2.2) |
| Volume air di log tidak sesuai kenyataan | Volume adalah **estimasi** (durasi × debit tetap), tidak ada flow sensor | Ukur debit pompa asli, update `FLOW_RATE_ML_PER_MINUTE` di `pump_config.h` |
| Bahasa di TFT Inggris | `language.json` di SD Card = `"en"` | Pilih bahasa Indonesia lewat menu 🌐 di app (ikut dikirim ke ESP32), atau ganti ke `"id"` di SD Card |
| Semua sudah dicoba, tetap aneh | Cache build / setting rusak | ESP32: `pio run -t clean`, upload ulang, format ulang SD Card. App: `fvm flutter clean`, uninstall app, install ulang |

---

## 6. Referensi File Penting

**Firmware ESP32** — repository [`airri-esp32`](https://github.com/imampri100/airri-esp32)

| File | Isi |
|---|---|
| `README.md` | Dokumentasi lengkap firmware, REST API, known issues |
| `platformio.ini` | Board, baud rate, versi library |
| `src/main.cpp` | Titik masuk, perakitan semua komponen |
| `src/infrastructure/config/pin_config.h` | Semua pin |
| `src/infrastructure/config/wifi_config.h` | Default SSID/password AP & STA, port HTTP |
| `src/infrastructure/config/pump_config.h` | Debit pompa |
| `src/infrastructure/config/file_config.h` | Path file di SD Card |
| `src/infrastructure/hardware/sensor_manager.h` | Kalibrasi soil moisture |
| `src/infrastructure/hardware/display_manager.cpp` | Layout layar TFT |
| `docs/storage.md` | Format log, rotasi bulanan, retensi, skema ID |
| `docs/smart-irrigation-api_postman_collection.json` | Koleksi Postman untuk semua endpoint |

**Mobile app** — repository [`airri-mobile`](https://github.com/imampri100/airri-mobile)

| File | Isi |
|---|---|
| `README.md` | Arsitektur, fitur, cara ganti ikon/splash/nama app |
| `.fvmrc` | Versi Flutter (3.44.2) |
| `pubspec.yaml` / `pubspec.lock` | Dependency & versi terkunci |
| `lib/infrastructure/irrigation/device_settings_service.dart` | Alamat default ESP32 |
| `lib/infrastructure/irrigation/irrigation_api_client.dart` | Pemanggilan REST API ke ESP32 |
| `lib/common/di/dio_di.dart` | Konfigurasi HTTP client (timeout) |
| `lib/application/irrigation/sync_service.dart` | Logika sinkronisasi log ke SQLite |
| `assets/translations/` | Teks UI Indonesia & Inggris |
| `android/app/build.gradle.kts` | Konfigurasi build Android (applicationId, signing) |
| `android/settings.gradle.kts` | Versi AGP & Kotlin |
| `android/gradle/wrapper/gradle-wrapper.properties` | Versi Gradle |
