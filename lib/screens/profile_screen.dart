import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/storage_service.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../widgets/app_watermark.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = StorageService();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  DateTime? _selectedDate;
  UserProfile? _currentProfile;
  bool _saving = false;

  final Color _primaryColor = const Color(0xFF5C55ED);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = await _storage.loadProfile();
    if (profile != null) {
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _selectedDate = profile.birthDate;
          _nameController.text = profile.name == 'User Baru' ? '' : profile.name;
          _heightController.text = profile.height?.toString() ?? '';
          _weightController.text = profile.weight?.toString() ?? '';
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square for profile
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Edit Foto Profil',
              toolbarColor: _primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              activeControlsWidgetColor: _primaryColor,
            ),
            IOSUiSettings(
              title: 'Edit Foto Profil',
              aspectRatioLockEnabled: true,
              resetButtonHidden: false,
              rotateButtonsHidden: false,
            ),
          ],
        );

        if (croppedFile != null && mounted) {
          setState(() {
            _currentProfile = _currentProfile?.copyWith(photoPath: croppedFile.path);
          });
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyesuaikan gambar')),
        );
      }
    }
  }

  Future<void> _save() async {
    final nameInput = _nameController.text.trim();
    final name = nameInput.isEmpty ? 'User Baru' : nameInput;
    
    setState(() => _saving = true);

    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    final updatedProfile = (_currentProfile ?? UserProfile(name: name)).copyWith(
      name: name,
      birthDate: _selectedDate,
      height: height,
      weight: weight,
      photoPath: _currentProfile?.photoPath,
    );

    await _storage.saveProfile(updatedProfile);

    if (mounted) {
      setState(() {
        _saving = false;
        _currentProfile = updatedProfile;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil diperbarui'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProfile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header / Avatar ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _primaryColor.withValues(alpha: 0.1), width: 2),
                            ),
                            child: _currentProfile?.photoPath != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(_currentProfile!.photoPath!),
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 48,
                                    backgroundColor: _primaryColor.withValues(alpha: 0.08),
                                    child: Icon(Icons.person_rounded, size: 48, color: _primaryColor),
                                  ),
                          ),
                        ),
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentProfile!.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'ID: ${_currentProfile!.uid ?? 'Loading...'}',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade500
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Personal Info Form ────────────────────────────────────
              const _SectionLabel(label: "INFORMASI PRIBADI"),
              const SizedBox(height: 12),
              _buildInputCard([
                _buildFieldLabel('Nama Lengkap'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputStyle('Masukkan nama Anda', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Tanggal Lahir'),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null 
                            ? 'Pilih Tanggal' 
                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} (${_calculateAge(_selectedDate!)} Tahun)",
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null ? Colors.grey.shade400 : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              
              const SizedBox(height: 24),
              const _SectionLabel(label: "DATA FISIK (UNTUK BMI)"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard([
                      _buildFieldLabel('TB (cm)'),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: _inputStyle('170', Icons.straighten_rounded),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputCard([
                      _buildFieldLabel('BB (kg)'),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: _inputStyle('65', Icons.monitor_weight_outlined),
                      ),
                    ]),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // ── BMI Result Widget (if available) ──────────────────────────
              if (_currentProfile?.bmi != null) 
                _buildBMICard(_currentProfile!.bmi!),

              const SizedBox(height: 12),

              // ── Save Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const AppWatermark(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildBMICard(double bmi) {
    String category = "Normal";
    Color color = const Color(0xFF10B981);
    if (bmi < 18.5) { category = "Kurus"; color = Colors.orange; }
    else if (bmi >= 25) { category = "Berlebih"; color = Colors.red; }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_rounded, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Indeks Massa Tubuh (BMI)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${bmi.toStringAsFixed(1)} — $category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(0xFF94A3B8)));
  }
}
