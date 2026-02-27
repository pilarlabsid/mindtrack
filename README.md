# 🧠 MindTrack

**MindTrack** adalah aplikasi Flutter untuk memonitor perangkat wearable pendeteksi stres dan kecemasan secara real-time. Aplikasi ini menampilkan data fisiologis seperti detak jantung, suhu kulit, tingkat gerakan, dan indeks stres dalam antarmuka yang modern dan minimal. Tersambung langsung ke ESP32 via Bluetooth Low Energy (BLE).

---

## ✨ Fitur Utama

- 📡 **BLE Integration** — Scan dan terhubung otomatis ke perangkat wearable ESP32 menggunakan BLE GATT.
- 👤 **Onboarding & Profil** — Personalisasi dengan nama pengguna, tersimpan langsung di secara lokal (SharedPreferences).
- 📊 **Dashboard Real-Time** — Indikator stres melingkar dengan animasi pulsa, dan kartu data fisiologis yang diperbarui otomatis saat data masuk dari sensor.
- 📈 **History** — Grafik garis stres interaktif 24 jam menggunakan `fl_chart`. Membaca memori data history selama 500 iterasi terakhir per *session*.
- 🔴🟠🟢 **Status Zona** — Relaxed (0–30) · Normal (31–60) · Stressed (61–100).
- 🔄 **Live Fallback / Mock Data** — Simulasi data wearable secara otomatis ketika koneksi BLE sedang terputus.

---

## 📡 Protokol BLE ESP32

MindTrack dirancang untuk membaca data berformat **JSON** yang dikirimkan melalui protokol BLE *Notify*.

### UUIDs
- **Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Data Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8` (Mode: `Notify`)

### Format Data JSON (Payload)

Data harus dikirimkan oleh ESP32 sebagai *String JSON bytes*:
```json
{"hr":78,"temp":36.5,"move":2,"stress":42,"ts":1709078400}
```

| Field | Tipe | Keterangan |
|---|---|---|
| `hr` | int | Detak Jantung / Heart Rate (BPM) |
| `temp` | float | Suhu kulit dalam °C |
| `move` | int | Tingkat pergerakan: `0` (Low), `1` (Medium), `2` (High) |
| `stress` | int | Indeks Stres (0 = Santai, 100 = Sangat Stres) |
| `ts` | int | Unix Timestamp saat pembacaan (opsional, jika kosong aplikasi akan menggunakan waktu lokal HP) |

> 💡 **Penting:** Karena batas MTU BLE (Maximum Transmission Unit) pada beberapa HP lama kadang sangat kecil (misal 20 bytes), aplikasi ini sudah dilengkapi sistem `_jsonBuffer` yang menambal potongan bytes JSON (*chunking*) secara otomatis sampai kurung kurawal `{ ... }` terpenuhi.

---

## 🗂️ Struktur Proyek

```
lib/
├── main.dart                  # Entry point, AppRoot (penentu Onboarding), & Navigasi
├── dashboard_screen.dart      # Halaman utama dengan data live vs mock
├── history_screen.dart        # Halaman grafik riwayat stres live vs mock
├── models/
│   ├── sensor_data.dart       # Model data sensor wearable (parse JSON)
│   └── user_profile.dart      # Model nama & device (SharedPreferences)
├── screens/
│   ├── onboarding_screen.dart # Halaman memasukkan nama pengguna pertama kali
│   └── scan_screen.dart       # Scanner Bluetooth ESP32 
├── services/
│   ├── ble_service.dart       # Otak BLE (scan, connect, parse format json)
│   └── storage_service.dart   # Local persistence memakai shared_preferences
└── widgets/
    ├── info_card.dart          
    └── stress_indicator.dart   
```

---

## 📦 Dependencies Utama

| Package | Fungsionalitas |
|---------|----------|
| `flutter_blue_plus` | ^8.2.1 — Standar terbaru BLE untuk Flutter |
| `shared_preferences` | ^2.5.4 — Local persistence session |
| `fl_chart` | ^1.1.1 — Render grafik garis & progress |

---

## 🛠️ Persiapan & Menjalankan

### iOS Simulator (Tanpa BLE Fisik, hanya Mock)

*Catatan: Simulator iOS dari Apple tidak mendukung simulasi BLE, kamu hanya akan melihat Mock Data UI.*

1. Buka simulator:
   ```bash
   xcrun simctl boot "iPhone 17 Pro"
   open -a Simulator
   ```
2. Jalankan aplikasi:
   ```bash
   flutter run -d "iPhone 17 Pro"
   ```

### 📱 iOS Fisik (Untuk Testing BLE Penuh)

Pastikan iPhone memakai iOS 13+.
1. Tancapkan USB ke Mac, tekan "Trust this Computer".
2. Buka workspace di Xcode: `open ios/Runner.xcworkspace`
3. Pilih **Runner** target > tab **Signing & Capabilities** > pilih akun Apple ID milikmu.
4. Kembali ke terminal lalu eksekusi:
   ```bash
   flutter run -d "iPhone Ujang"
   ```

### 🤖 Android Device (Fisik / Emulator)
1. Tancapkan Android yang telah aktif **USB Debugging** (Developer Options).
2. Konfirmasi Popup Fingerprint RSA di HP.
3. Jalankan aplikasi:
   ```bash
   flutter run
   ```

> Privasi Android membutuhkan GPS/Location hidup agar *scanner* BLE dapat melihat `MindTrack-ESP32` milikmu.

---

## 🔧 Troubleshooting

- **Gagal Scan BLE Android:** Pastikan Location dan Bluetooth di Notification Bar aktif. Permission (Fine Location & Bluetooth Connect) sudah terisi di `AndroidManifest.xml`.
- **JSON tidak muncul di Dashboard:** Cek serial monitor ESP32, pastikan JSON *string*-nya tidak menggunakan *carriage return* aneh yang merusak *decoder utf8*.

---

## 📄 Lisensi

MIT License — bebas digunakan dan dimodifikasi untuk kebutuhan pribadi maupun purwarupa komersial IoT.
