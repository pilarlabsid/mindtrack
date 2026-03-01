import 'package:flutter/material.dart';
import '../widgets/app_watermark.dart';

/// Halaman Edukasi Stres Premium – Memberikan wawasan kesehatan mendalam
/// tentang pengelolaan stres berbasis data biometrik.
class StressEduScreen extends StatelessWidget {
  const StressEduScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar Premium ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF5C55ED),
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Pusat Wawasan Stres',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5C55ED), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Icon(
                        Icons.psychology_rounded,
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Konten Edukasi ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // 1. Kartu Pengantar Highlight
                _buildHeroCard(),
                const SizedBox(height: 24),

                // 2. Zona Indeks Stres (The "Science")
                const _SectionLabel(label: "PANDUAN INDEKS STRES"),
                const SizedBox(height: 12),
                const _LevelTile(
                  title: '0 – 30: Zona Restorasi 😊',
                  color: Color(0xFF10B981),
                  desc: 'Sistem saraf parasimpatis dominan. Tubuh sedang memperbaiki sel dan mengisi ulang energi mental.',
                ),
                const _LevelTile(
                  title: '31 – 60: Zona Kinerja 😐',
                  color: Color(0xFFF59E0B),
                  desc: 'Kondisi waspada dan fokus. Ini adalah stres positif (Eustress) yang memacu produktivitas.',
                ),
                const _LevelTile(
                  title: '61 – 100: Zona Tekanan 😟',
                  color: Color(0xFFEF4444),
                  desc: 'Mode Lawan-atau-Lari aktif. Jika bertahan lama, dapat menyebabkan kelelahan kronis.',
                ),
                const SizedBox(height: 28),

                // 3. Gejala Fisik yang Terdeteksi
                const _SectionLabel(label: "GEJALA FISIK YANG TERPANTAU"),
                const SizedBox(height: 12),
                _buildSymptomGrid(),
                const SizedBox(height: 28),

                // 4. Teknik Manajemen Interaktif
                const _SectionLabel(label: "TEKNIK RELAKSASI CEPAT"),
                const SizedBox(height: 12),
                const _ActionCard(
                  icon: Icons.air_rounded,
                  accentColor: Color(0xFF06B6D4),
                  title: 'Pernapasan Kotak (Box Breathing)',
                  desc: 'Metode Navy SEAL: Tarik 4s, Tahan 4s, Buang 4s, Tahan 4s. Sangat efektif menstabilkan IBI (Inter-Beat Interval).',
                ),
                const _ActionCard(
                  icon: Icons.self_improvement_rounded,
                  accentColor: Color(0xFF8B5CF6),
                  title: 'Relaksasi Otot Progresif',
                  desc: 'Tegangkan otot bahu selama 5 detik lalu lepaskan mendadak. Ini mengirim sinyal "Aman" ke otak.',
                ),
                const _ActionCard(
                  icon: Icons.water_drop_rounded,
                  accentColor: Color(0xFF3B82F6),
                  title: 'Hidrasi & Suhu Kulit',
                  desc: 'Minum air dingin dapat membantu menurunkan suhu kulit yang meningkat akibat kecemasan.',
                ),
                
                const SizedBox(height: 32),
                
                // 5. Kesimpulan Kesehatan
                _buildSummaryBox(),
                
                const SizedBox(height: 20),
                const AppWatermark(),
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF5C55ED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF5C55ED), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Mengenal Stres Anda", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Stres bukan musuh, melainkan sinyal dari tubuh. MindTrack menggunakan algoritma 'Fusion Index' yang menggabungkan 4 sensor utama untuk membaca kondisi sistem saraf otonom Anda secara presisi.",
            style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6), // Slate 600
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: const [
        _SymptomBox(icon: Icons.favorite_rounded, label: 'Laju Jantung', desc: 'Detak meningkat (BPM naik)'),
        _SymptomBox(icon: Icons.water_drop_rounded, label: 'GSR / Keringat', desc: 'Konduktansi kulit naik (Lembab)'),
        _SymptomBox(icon: Icons.timeline_rounded, label: 'HRV Rendah', desc: 'Variabilitas detak kaku/statis'),
        _SymptomBox(icon: Icons.thermostat_rounded, label: 'Suhu Kulit', desc: 'Meningkat di area telapak tangan'),
      ],
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Pantau data secara rutin untuk memahami pola stres harian Anda. Kesehatan mental dimulai dari kesadaran diri.",
              style: TextStyle(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4), // Slate 400
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF64748B)), // Slate 500
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String title;
  final String desc;
  final Color color;
  const _LevelTile({required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5)), // Slate 600
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  const _SymptomBox({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)), // Slate 100
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF5C55ED)),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))), // Slate 500
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String desc;
  const _ActionCard({required this.icon, required this.accentColor, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5)), // Slate 500
              ],
            ),
          ),
        ],
      ),
    );
  }
}
