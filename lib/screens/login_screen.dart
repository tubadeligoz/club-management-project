import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage; // <-- hata mesajını burada tut

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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

    String? result;
    try {
      result = await _authService.signIn(email, password);
    } catch (_) {
      result = 'Bir sorun oluştu. Lütfen tekrar deneyin.';
    }

    if (!mounted) return;

    if (result == null) {
      // Başarılı giriş
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _errorMessage = null;
      });
      // Yönlendirme veya başarılı mesaj:
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giriş başarılı.')));
    } else {
      // Spesifik hata mesajını ekranda göster
      setState(() {
        _errorMessage = result;
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/Dogus.logo.png',
                height: 150,
                errorBuilder: (ctx, err, st) => const Icon(Icons.account_circle, size: 150, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: const Color.fromARGB(255, 249, 19, 2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.red),
                child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text("Giriş Yap", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Kayıt Ol"),
              )
            ],
          ),
        ),
      ),
    );
  }
}