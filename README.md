# 🧠 MindTrack Pro

**MindTrack Pro** adalah aplikasi Flutter canggih untuk memonitor perangkat wearable pendeteksi stres dan kesehatan mental secara real-time. Aplikasi ini tidak hanya menampilkan data mentah, tetapi juga memberikan analisis cerdas dan saran tindakan berdasarkan profil fisik serta data biometrik pengguna (Detak Jantung, HRV, GSR, Suhu, dan Akselerasi).

---

## ✨ Fitur Utama

- 🧠 **Dynamic Stress Insights** — Analisis real-time "Mengapa" stres terjadi dan "Apa" yang harus dilakukan (Saran Tindakan) berdasarkan matriks keputusan multi-dimensi.
- ⚖️ **Personalized Analytics** — Algoritma deteksi stres yang menyesuaikan dengan **Usia, Tinggi Badan, Berat Badan (BMI)**, dan Heart Rate Reserve (HRR).
- 📡 **BLE Integration** — Scan dan terhubung otomatis ke perangkat wearable ESP32 menggunakan protokol GATT dengan sistem buffer JSON yang stabil.
- 👤 **Advanced Profiling** — Setup profil lengkap (Nama, Tanggal Lahir, TB, BB) dengan fitur edit foto profil (Crop & Rotate).
- 📊 **Dashboard Real-Time** — Indikator stres melingkar premium dengan animasi pulsa dan kartu data fisiologis terperinci.
- 📈 **History & Edukasi** — Grafik riwayat stres 24 jam interaktif dan modul edukasi manajemen stres terintegrasi.
- 🔄 **Live Fallback** — Simulasi data cerdas (*Mock Data*) saat koneksi terputus untuk memastikan UI tetap interaktif di simulator maupun device fisik.

---

## 📡 Protokol BLE ESP32 (V2)

MindTrack Pro membaca data berformat **JSON** melalui paket *Notify*.

### UUIDs
- **Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8`

### Format Data JSON (Payload)
ESP32 harus mengirimkan string JSON sebagai berikut:
```json
{
  "hr": 75,
  "ibi": 800,
  "hrv": 45,
  "t": 36.5,
  "st": 42,
  "g": 35,
  "ir": 1200,
  "ax": 0.1,
  "ay": 0.2,
  "az": 9.8
}
```

---

## 🛠️ Panduan Build & Running

### 🤖 Android
1. **Persiapan:** Aktifkan **USB Debugging** dan **Location/GPS** pada perangkat fisik.
2. **Build Release (APK):** Aturan ProGuard dikelola via `android/app/proguard-rules.pro`.
3. **Run:** `flutter run --release`

### 🍎 iOS
1. **Persiapan:** Buka `ios/Runner.xcworkspace` di Xcode dan atur **Signing & Capabilities**.
2. **Izin Privasi:** Bluetooth, Kamera, dan Galeri dikonfigurasi di `Info.plist`.
3. **Run:** `flutter run --release`

### 💻 Simulator vs Physical Device
| Fitur | Simulator (iOS/Android) | Device Fisik |
|-------|--------------------------|--------------|
| **Koneksi BLE** | ❌ (Mock Data) | ✅ Berfungsi Penuh |
| **Edit Foto** | ✅ Berfungsi | ✅ Berfungsi |
| **Analisis Stres** | ✅ Berfungsi (via Mock) | ✅ Berfungsi (via Sensor) |

---

## 🗂️ Struktur Proyek

```
lib/
├── main.dart                  # Entry Point & Navigasi Utama
├── dashboard_screen.dart      # Dashboard Utama & Kartu Analisis
├── history_screen.dart        # Grafik Riwayat Stres 24 Jam
├── models/
│   ├── sensor_data.dart       # Logika Matriks Keputusan & Analisis Stres
│   └── user_profile.dart      # Model User + Dinamic Age & BMI logic
├── screens/
│   ├── onboarding_screen.dart # Setup profil awal & intro modern
│   ├── profile_screen.dart    # Management profil & Image Cropper
│   ├── scan_screen.dart       # BLE Scanner (ESP32)
│   ├── stress_edu_screen.dart # Modul edukasi manajemen stres
│   └── sensor_detail_screen.dart # Detail data mentah sensor
├── services/
│   ├── ble_service.dart       # BLE Engine with JSON Buffering
│   └── storage_service.dart   # Persistensi data lokal (SharedPreferences)
└── widgets/
    ├── stress_indicator.dart  # Custom Gauges & Progress Indicators
    ├── info_card.dart         # UI Card reusable untuk sensor
    └── app_watermark.dart     # Label branding aplikasi
```

---

## 🏢 Developers & Credits

Dikembangkan oleh **Pilar Labs**.

---

## 📄 Lisensi
MIT License — Solusi IoT untuk Digital Mental Health yang Presisi.
