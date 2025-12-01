import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Ana renk paletini tanımlayalım
  static const Color _primaryColor = Color.fromARGB(255, 164, 19, 9); // Kırmızı
  static const Color _secondaryColor = Color(0xFFEEEEEE); // Açık Gri

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'E-posta ve şifre boş olamaz.';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = result.user;
      if (user == null) {
        setState(() {
          _errorMessage = 'Giriş başarısız oldu. Lütfen tekrar deneyin.';
        });
      } else if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Lütfen e-posta adresinizi doğrulayın.';
        });
      } else {
        // Başarılı giriş: AuthWrapper main.dart'de otomatik yönlendirir.
        _emailController.clear();
        _passwordController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Hata mesajını daha kullanıcı dostu bir şekilde gösterelim
        if (e.code == 'user-not-found') {
          _errorMessage = 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Hatalı şifre. Lütfen tekrar deneyin.';
        } else {
          _errorMessage = e.message ?? e.code;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Özel bir Giriş Alanı Widget'ı (TextField) oluşturalım
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required TextInputType keyboardType,
    required bool enabled,
    bool obscureText = false,
    IconData? icon,
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
          labelText: labelText,
          prefixIcon: icon != null ? Icon(icon, color: _primaryColor.withOpacity(0.7)) : null,
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
      backgroundColor: _secondaryColor, // Arka plan rengini hafifçe değiştirelim
      body: Center(
        child: SingleChildScrollView(
          // Üst boşluğu ve logo‑form arası boşluğu azaltmak için top padding'i küçültüldü
          padding: const EdgeInsets.fromLTRB(30, 4, 30, 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Butonları ve alanları genişletmek için
            children: [
              // Logo (Çerçevesiz - olduğu gibi göster)
              SizedBox(
                width: 280, // büyütüldü (önceden 240)
                height: 280, // büyütüldü (önceden 240)
                child: Image.asset(
                  'assets/icon-removebg-preview.png',
                  fit: BoxFit.contain,
                  width: 200,
                  height: 200,
                  errorBuilder: (ctx, err, st) => Container(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.account_circle,
                      size: 180, // fallback ikonu da büyütüldü
                      color: _primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 0), // logo ile e‑posta arasındaki boşluğu küçülttük

              // E-posta Alanı
              _buildTextField(
                controller: _emailController,
                labelText: "E-posta",
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),

              // Şifre Alanı
              _buildTextField(
                controller: _passwordController,
                labelText: "Şifre",
                keyboardType: TextInputType.visiblePassword,
                enabled: !_isLoading,
                obscureText: true,
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 20),

              // Hata Mesajı
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

              // Giriş Yap Butonu
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5), // Butona daha belirgin bir gölge
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0, // Container'ın gölgesini kullanacağımız için ElevatedButton'ın kendi gölgesini sıfırlayalım
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          "Giriş Yap",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 10),
              
              // Kayıt Ol Butonu
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text(
                  "Hesabın yok mu? Kayıt Ol",
                  style: TextStyle(color: _primaryColor.withOpacity(0.8), fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}