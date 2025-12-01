import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  final AuthService _authService = AuthService();

  // --- EKLENDİ: İlgi alanları değişkenleri 
  final List<String> _allInterests = [
    "Teknoloji",
    "Bilim",
    "Tarih",
    "Sanat",
    "Yabancı Dil",
    "Spor",
    "Tasarım",
    "Endüstri",
    "Girişimcilik",
    "Gastronomi",
    "İletişim",
    "İşletme"
  ];
  final List<String> _selectedInterests = [];


  // Ana renk paletini tanımlayalım
  static const Color _primaryColor = Color.fromARGB(255, 241, 21, 6); // Kırmızı
  static const Color _secondaryColor = Color(0xFFEEEEEE); // Açık Gri (Arka plan)

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Odaklanmayı kaldır
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final ad = _adController.text.trim();
    final soyad = _soyadController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validasyon
    if (ad.isEmpty || soyad.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tüm alanlar doldurulmalıdır.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Şifreler eşleşmiyor.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Şifre en az 6 karakter olmalıdır.';
      });
      return;
    }

    // Kayıt işlemi
    final result = await _authService.register(email, password, ad, soyad);

    if (!mounted) return;

    if (result == null) {
      // Başarılı kayıt
      setState(() {
        _successMessage = 'Kayıt başarılı! Lütfen e-postanızı doğrulayın.';
      });

      // Seçili ilgi alanları varsa Firestore'da kullanıcı dokümanına kaydet (merge: true)
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'interests': _selectedInterests}, SetOptions(merge: true));
        }
      } catch (e) {
        // Sessizce loglayalım
        // ignore: avoid_print
        print('Interests save error: $e');
      }

      // Alanları temizleme
      _adController.clear();
      _soyadController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _selectedInterests.clear();

      // 2 saniye sonra login ekranına yönlendir
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // Hata mesajı
      setState(() {
        _errorMessage = result;
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Özel bir Giriş Alanı Widget'ı (TextField) oluşturalım
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), // Hafif bir alt gölge
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 205, 23, 10).withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // Kenarlığı kaldırarak daha yumuşak bir görünüm
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        // Başlık kaldırıldı, arka plan şeffaf yapıldı
        title: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white), // Geri butonu rengi
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 8, 30, 30), // Üst boşluğu küçülttüm
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kayıt İkonu Alanı (Daha şık bir gölge)
              Container(
                margin: const EdgeInsets.only(bottom: 12), // Alt boşluğu küçülttüm
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 147, 20, 11).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_alt_1, // İkonu biraz değiştirdim
                  size: 30, // Logo küçültüldü
                  color: Color.fromARGB(255, 16, 14, 14),
                ),
              ),

              // Üst başlık kaldırıldı; boşluk daha da küçültüldü
              const SizedBox(height: 8),

              // Giriş Alanları
              _buildTextField(
                controller: _adController,
                hintText: 'Ad',
                enabled: !_isLoading,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _soyadController,
                hintText: 'Soyad',
                enabled: !_isLoading,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _emailController,
                hintText: 'E-posta',
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _passwordController,
                hintText: 'Şifre',
                enabled: !_isLoading,
                obscureText: true,
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Şifre Tekrar',
                enabled: !_isLoading,
                obscureText: true,
                icon: Icons.lock_reset,
              ),

              const SizedBox(height: 15),

              // EKLENDİ: İlgi Alanları Seçimi UI
              const Text(
                'İlgi Alanları',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: _isLoading
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                if (!_selectedInterests.contains(interest)) {
                                  _selectedInterests.add(interest);
                                }
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                    selectedColor: _primaryColor.withOpacity(0.12),
                    checkmarkColor: _primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? _primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              // -----------------------------------------------------------

              // Hata/Başarı Mesajları
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: _primaryColor),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Kayıt Ol Butonu
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 189, 27, 15).withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5), // Butona daha belirgin bir gölge
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: const Color.fromARGB(255, 185, 27, 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0, // Container'ın gölgesini kullanıyoruz
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Kayıt Ol',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // Giriş Yap Butonu
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text(
                  'Zaten hesabınız var mı? Giriş Yap',
                  style: TextStyle(color: const Color.fromARGB(255, 133, 14, 5).withOpacity(0.8), fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}