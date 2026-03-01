/// Holds a single snapshot of sensor readings from the MindTrack wearable device.
class SensorData {
  final int heartRate;    // BPM
  final int ibi;          // ms  — Inter-Beat Interval
  final int hrv;          // ms  — Heart Rate Variability SDNN
  final double temperature; // °C
  final int motionScore;  // 0–100 — computed from movement
  final int stressIndex;  // 0–100 — raw st from device
  final int gsrPercent;   // 0–100% — skin conductance
  final int irRaw;        // raw IR
  final double accelX;    
  final double accelY;    
  final double accelZ;    
  final DateTime timestamp;

  const SensorData({
    required this.heartRate,
    required this.ibi,
    required this.hrv,
    required this.temperature,
    required this.motionScore,
    required this.stressIndex,
    required this.gsrPercent,
    required this.irRaw,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.timestamp,
  });

  // ── Smart Processing (Age & BMI Aware) ───────────────────────────────────

  /// Calculates a more accurate stress index adjusted for age and BMI.
  int getAdjustedStress(int? age, double? height, double? weight) {
    if (age == null) return stressIndex;

    double adjustmentFactor = 1.0;
    
    // 1. Age Normalization (HRV naturally declines with age)
    if (age > 30) adjustmentFactor -= 0.05;
    if (age > 45) adjustmentFactor -= 0.10;
    if (age > 60) adjustmentFactor -= 0.15;

    // 2. BMI Influence
    if (height != null && weight != null && height > 0) {
      final hMeter = height / 100.0;
      final bmiValue = weight / (hMeter * hMeter);
      if (bmiValue > 25) adjustmentFactor -= 0.05;
      if (bmiValue > 30) adjustmentFactor -= 0.08;
    }

    // 3. Heart Rate Reserve adjustment
    int mhr = 220 - age;
    double hrIntensity = heartRate / mhr;

    int adjusted = (stressIndex * adjustmentFactor).toInt();
    if (hrIntensity > 0.8) adjusted += 10;
    
    return adjusted.clamp(0, 100);
  }

  /// Label based on age-adjusted stress index.
  String getStressLabel(int? age, double? height, double? weight) {
    final idx = getAdjustedStress(age, height, weight);
    if (idx <= 30) return 'Santai 😊';
    if (idx <= 60) return 'Normal 😐';
    return 'Tegang 😟';
  }

  /// High-granularity analysis based on multi-dimensional sensor data.
  String getStressAnalysis(int? age, double? height, double? weight) {
    final idx = getAdjustedStress(age, height, weight);
    final isMoving = motionScore > 40;

    // --- CATEGORY: TEGANG (HIGH STRESS) ---
    if (idx > 60) {
      if (heartRate > 100 && !isMoving) {
        return "Stres Mental Tinggi: Detak jantung Anda sangat cepat padahal tubuh tidak banyak bergerak. Ini menandakan lonjakan kortisol atau kecemasan akut.";
      }
      if (gsrPercent > 70) {
        return "Reaksi Emosional Kuat: Aktivitas kelenjar keringat (GSR) meningkat drastis, menunjukkan respon 'fight or flight' terhadap pemicu eksternal.";
      }
      if (hrv < 20) {
        return "Kelelahan Sistem Saraf: Variabilitas detak jantung Anda sangat rendah. Sistem saraf Anda kehilangan fleksibilitas untuk kembali tenang.";
      }
      if (temperature > 37.5) {
        return "Beban Termal & Stres: Suhu tubuh meningkat bersamaan dengan indeks stres, mungkin karena lingkungan panas atau kelelahan fisik yang berlebihan.";
      }
      return "Stres Akumulatif: Data biometrik menunjukkan beban sistem saraf yang tinggi dari berbagai faktor gabungan.";
    }

    // --- CATEGORY: NORMAL (MODERATE) ---
    else if (idx > 30) {
      if (isMoving) {
        return "Aktivitas Produktif: Detak jantung dan stres berada dalam rentang normal untuk tubuh yang sedang aktif bergerak.";
      }
      if (gsrPercent > 50) {
        return "Interaksi Sosial/Kerja: Ada sedikit lonjakan respons kulit, mungkin karena percakapan mendalam atau fokus pada tugas yang menantang.";
      }
      return "Kondisi Stabil: Sistem tubuh Anda bekerja dengan efisien dalam mode fungsional harian.";
    }

    // --- CATEGORY: SANTAI (LOW STRESS) ---
    else {
      if (heartRate < 65 && hrv > 40) {
        return "Pemulihan Optimal: Detak jantung rendah dan HRV tinggi menunjukkan fase restorasi yang sangat baik bagi organ tubuh.";
      }
      if (temperature < 36.2) {
        return "Relaksasi Dalam: Tubuh berada dalam mode hemat energi, sangat baik untuk meditasi atau persiapan tidur.";
      }
      return "Ketenangan Mental: Pikiran dan tubuh Anda sedang dalam sinkronisasi yang tenang dan seimbang.";
    }
  }

  /// Highly specific recommendations based on the analysis above.
  String getRecommendation(int? age, double? height, double? weight) {
    final idx = getAdjustedStress(age, height, weight);
    final isMoving = motionScore > 40;

    // --- RECOMMENDATIONS FOR TEGANG (HIGH STRESS) ---
    if (idx > 60) {
      if (heartRate > 100 && !isMoving) {
        return "Segera lakukan pernapasan perut (Diaphragmatic Breathing). Hirup 4 detik melalui hidung, buang 6 detik melalui mulut. Ulangi 10 kali untuk menurunkan detak jantung.";
      }
      if (gsrPercent > 70) {
        return "Basuh wajah atau lengan dengan air dingin. Suhu dingin akan memicu refleks penyelaman yang secara instan menenangkan sistem saraf simpatis Anda.";
      }
      if (hrv < 20) {
        return "Anda butuh istirahat total. Matikan layar gawai, tutup mata selama 5 menit, dan biarkan sistem saraf Anda melakukan reboot tanpa stimulasi visual.";
      }
      return "Cari tempat yang tenang dengan udara segar. Lakukan peregangan leher dan bahu untuk melepas ketegangan otot yang menghambat aliran darah ke otak.";
    }

    // --- RECOMMENDATIONS FOR NORMAL (MODERATE) ---
    else if (idx > 30) {
      if (isMoving) {
        return "Pertahankan momentum ini. Pastikan Anda minum air putih (250ml) setiap 30 menit agar volume darah tetap stabil dan jantung tidak bekerja terlalu keras.";
      }
      return "Gunakan zona fokus ini untuk menyelesaikan tugas sulit. Namun, pastikan berdiri dan berjalan selama 2 menit setiap satu jam untuk menjaga sirkulasi.";
    }

    // --- RECOMMENDATIONS FOR SANTAI (LOW STRESS) ---
    else {
      if (hrv > 50) {
        return "Waktu yang tepat untuk refleksi atau merencanakan strategi besar. Kejelasan mental Anda sedang berada di puncak tertingginya.";
      }
      return "Sangat baik untuk melanjutkan hobi ringan atau membaca buku. Tubuh Anda sedang mengisi ulang tangki energi untuk tantangan berikutnya.";
    }
  }

  // ── Basic Raw Labels ──────────────────────────────────────────────────────

  String get stressLabel {
    if (stressIndex <= 30) return 'Santai 😊';
    if (stressIndex <= 60) return 'Normal 😐';
    return 'Tegang 😟';
  }

  String get stressLabelShort {
    if (stressIndex <= 30) return 'Santai';
    if (stressIndex <= 60) return 'Normal';
    return 'Tegang';
  }

  String get hrvLabel {
    if (hrv <= 10) return 'Rendah';
    if (hrv <= 30) return 'Normal';
    return 'Baik';
  }

  String get gsrLabel {
    if (gsrPercent <= 30) return 'Kering';
    if (gsrPercent <= 60) return 'Normal';
    return 'Lembab';
  }

  String get activityLabel {
    if (motionScore <= 20) return 'Istirahat';
    if (motionScore <= 50) return 'Ringan';
    if (motionScore <= 75) return 'Sedang';
    return 'Aktif';
  }

  String get heartRateLabel {
    if (heartRate < 60) return 'Rendah';
    if (heartRate <= 100) return 'Normal';
    if (heartRate <= 140) return 'Sedikit Tinggi';
    return 'Tinggi';
  }

  String get temperatureLabel {
    if (temperature < 36.0) return 'Rendah';
    if (temperature <= 37.5) return 'Normal';
    return 'Demam';
  }

  double get accelMagnitude {
    final sum = accelX * accelX + accelY * accelY + accelZ * accelZ;
    return _sqrt(sum);
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double z = v;
    for (int i = 0; i < 20; i++) {
      z = (z + v / z) / 2;
    }
    return z;
  }

  factory SensorData.fromBleJson(Map<String, dynamic> json) {
    final ax = (json['ax'] as num?)?.toDouble() ?? 0.0;
    final ay = (json['ay'] as num?)?.toDouble() ?? 0.0;
    final az = (json['az'] as num?)?.toDouble() ?? 9.8;
    
    final mag = (ax*ax + ay*ay + az*az);
    final motionScore = ((mag - 96).abs() * 0.5).clamp(0.0, 100.0).toInt();

    return SensorData(
      heartRate:   (json['hr']  as int?)  ?? 0,
      ibi:         (json['ibi'] as int?)  ?? 0,
      hrv:         (json['hrv'] as int?)  ?? 0,
      temperature: (json['t']   as num?)?.toDouble() ?? 0.0,
      motionScore: motionScore,
      stressIndex: ((json['st'] as int?) ?? 0).clamp(0, 100),
      gsrPercent:  ((json['g']  as int?) ?? 0).clamp(0, 100),
      irRaw:       (json['ir']  as int?)  ?? 0,
      accelX:      ax,
      accelY:      ay,
      accelZ:      az,
      timestamp:   DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hr':  heartRate,
      'ibi': ibi,
      'hrv': hrv,
      't':   temperature,
      'st':  stressIndex,
      'g':   gsrPercent,
      'ir':  irRaw,
      'ax':  accelX,
      'ay':  accelY,
      'az':  accelZ,
      'ts':  timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}
