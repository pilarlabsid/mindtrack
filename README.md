# 🧠 MindTrack

**MindTrack** adalah aplikasi Flutter premium untuk memonitor perangkat wearable pendeteksi stres dan kecemasan secara real-time. Aplikasi ini menggabungkan data fisiologis mentah dengan profil fisik pengguna untuk memberikan analisis kesehatan mental yang akurat, personal, dan informatif.

---

## ✨ Fitur Unggulan Modern

- 📡 **BLE Integration** — Scan dan terhubung otomatis ke perangkat wearable ESP32 menggunakan protokol BLE GATT yang stabil.
- 🧘 **Wawasan Stres Dinamis** — Matriks keputusan pintar yang menganalisis kombinasi Detak Jantung, GSR, HRV, dan Suhu untuk menjelaskan "Kenapa" Anda stres dan memberikan "Saran Spesifik" untuk normalisasi.
- 👤 **Profil Biometrik Cerdas** — Penghitungan **BMI** otomatis dan usia dinamis (berdasarkan Tanggal Lahir) untuk menyesuaikan ambang batas stres secara medis.
- 📸 **Editor Foto Profil** — Integrasi editor foto (Crop & Rotate) untuk personalisasi identitas pengguna yang sempurna.
- 📊 **Dashboard Real-Time** — Indikator stres melingkar dengan animasi pulsasi, serta kartu data fisiologis yang diperbarui instan tanpa delay.
- 📈 **History Interaktif** — Grafik garis stres 24 jam menggunakan `fl_chart` untuk melacak tren kesehatan mental jangka panjang.
- 🔴🟠🟢 **Status Kesehatan** — Santai (0–30) · Normal (31–60) · Tegang (61–100).

---

## 📡 Protokol BLE ESP32

MindTrack membaca data berformat **JSON** yang dikirimkan melalui protokol BLE *Notify*.

### UUIDs
- **Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Data Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8`

### Format Data JSON (Payload)

```json
{
  "hr": 78,
  "ibi": 769,
  "hrv": 45,
  "t": 36.5,
  "g": 12,
  "st": 42,
  "ax": 0.1,
  "ay": 0.05,
  "az": 9.8,
  "ts": 1709078400
}
```

| Field | Keterangan |
|---|---|
| `hr` | Detak Jantung (BPM) |
| `ibi` | Inter-Beat Interval (ms) |
| `hrv` | Heart Rate Variability (ms) |
| `t` | Suhu Kulit (°C) |
| `g` | GSR / Skin Conductance (%) |
| `st` | Indeks Stres Raw (0-100) |
| `ax, ay, az` | Data Akselerometer |

---

## 🗂️ Struktur Proyek Terbaru

```
lib/
├── main.dart                  # Core logic & App Routing
├── dashboard_screen.dart      # Dashboard dengan 'Stress Insight Card'
├── history_screen.dart        # Visualisasi tren stres fl_chart
├── models/
│   ├── sensor_data.dart       # Algoritma analisis stres & rekomendasi cerdas
│   └── user_profile.dart      # Model profil (Name, BirthDate, BMI logic)
├── screens/
│   ├── onboarding_screen.dart # Setup awal (Nama, DOB, TB, BB)
│   ├── profile_screen.dart    # Manajemen profil & Editor foto (Image Cropper)
│   └── scan_screen.dart       # BLE Device Scanner
├── services/
│   ├── ble_service.dart       # Sinkronisasi data BLE 
│   └── storage_service.dart   # Persistence data lokal (SharedPreferences)
```

---

## 📦 Dependencies Utama

| Package | Peran |
|---------|-------|
| `flutter_blue_plus` | Konektivitas BLE Low Energy |
| `image_cropper` | Editor foto profil (Crop/Rotate) |
| `image_picker` | Pengambilan gambar galeri/kamera |
| `fl_chart` | Render grafik data biometrik |
| `shared_preferences` | Penyimpanan profil lokal |

---

## 🛠️ Build & Development

1. **Persiapan Android:** 
   Pastikan `android/app/proguard-rules.pro` dikonfigurasi untuk menghindari error R8 pada library `image_cropper`.
2. **Setup BLE:** 
   Aktifkan GPS/Location dan Bluetooth di perangkat fisik untuk melakukan scanning.
3. **Run:**
   ```bash
   flutter pub get
   flutter run --release
   ```

---

## 📄 Lisensi

MIT License — Dikembangkan oleh Pilarlabs ID / MindTrack Team.
