import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import '../widgets/app_watermark.dart';

/// Halaman Onboarding Premium – Menjelaskan fitur dan melakukan 
/// setup profil awal (Nama, Tanggal Lahir, TB, BB).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  final _storage = StorageService();
  int _currentPage = 0;
  bool _saving = false;
  DateTime? _selectedBirthDate;

  final Color _indigo = const Color(0xFF5C55ED);
  final Color _slate900 = const Color(0xFF0F172A);
  final Color _slate600 = const Color(0xFF475569);
  final Color _slate300 = const Color(0xFFCBD5E1);

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _indigo,
              onPrimary: Colors.white,
              onSurface: _slate900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticFeedback.vibrate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tolong masukkan nama Anda')),
        );
      }
      return;
    }

    if (_selectedBirthDate == null) {
      HapticFeedback.vibrate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tolong pilih tanggal lahir Anda')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    final profile = UserProfile(
      name: name,
      birthDate: _selectedBirthDate,
      height: height,
      weight: weight,
    );

    await _storage.saveProfile(profile);
    await _storage.setOnboarded();

    HapticFeedback.mediumImpact();
    widget.onCompleted();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Latar Belakang Gradien Halus ─────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    _indigo.withValues(alpha: 0.03),
                    const Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Konten PageView ──────────────────────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: [
              _buildIntroPage(
                icon: Icons.auto_awesome_rounded,
                title: "Kuasai Ketenangan\nMental Anda",
                desc: "MindTrack membantu Anda mendeteksi lonjakan stres secara real-time untuk menjaga kesehatan sistem saraf Anda.",
              ),
              _buildIntroPage(
                icon: Icons.insights_rounded,
                title: "Teknologi Fusion\nBiometrik",
                desc: "Menggabungkan data Detak Jantung, GSR, dan Suhu Kulit untuk analisis stres yang sangat akurat dan personal.",
              ),
              _buildSetupPage(),
            ],
          ),

          // ── Footer: Indikator & Tombol ───────────────────────────────
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                if (_currentPage < 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (idx) => _buildIndicator(idx == _currentPage)),
                  ),
                  const SizedBox(height: 32),
                ],
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _indigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _currentPage == 2 ? 'Selesai & Mulai' : 'Lanjutkan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                if (_currentPage < 2) ...[
                  const SizedBox(height: 12),
                  const AppWatermark(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 24 : 8,
      decoration: BoxDecoration(
        color: active ? _indigo : _indigo.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildIntroPage({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: _indigo),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _slate900, height: 1.2),
          ),
          const SizedBox(height: 20),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _slate600, height: 1.6),
          ),
          const SizedBox(height: 80), // Space for footer
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personalisasi Profil",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Data fisik membantu perhitungan stres yang lebih akurat secara medis.",
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),

          _buildLabel("Nama Lengkap"),
          _buildTextField(_nameController, "Masukkan nama Anda", Icons.person_rounded),
          const SizedBox(height: 20),

          _buildLabel("Tanggal Lahir"),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: _indigo.withValues(alpha: 0.5), size: 20),
                  const SizedBox(width: 16),
                  Text(
                    _selectedBirthDate == null 
                      ? "Pilih Tanggal Lahir" 
                      : "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}",
                    style: TextStyle(
                      color: _selectedBirthDate == null ? _slate300 : _slate900,
                      fontSize: 14
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Tinggi (cm)"),
                    _buildTextField(_heightController, "170", Icons.straighten_rounded, keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Berat (kg)"),
                    _buildTextField(_weightController, "65", Icons.monitor_weight_rounded, keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _slate300, fontSize: 14),
          prefixIcon: Icon(icon, color: _indigo.withValues(alpha: 0.5), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
