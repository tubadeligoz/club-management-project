import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authService = AuthService();
      String? errorMessage = await authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _adController.text.trim(),
        _soyadController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Lütfen e-posta adresinizi kontrol edin ve hesabınızı doğrulayın.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              
              TextFormField(
                controller: _adController,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad alanı boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              
              TextFormField(
                controller: _soyadController,
                decoration: const InputDecoration(labelText: 'Soyad'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyad alanı boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Okul E-postası'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta alanı boş bırakılamaz.';
                  }
                  
                  if (!value.contains('@') || (!value.endsWith('dogus.edu.tr'))) {
                    return 'Geçersiz e-posta. Sadece okul e-postası (dogus.edu.tr) kabul edilir.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              
              TextFormField(
                controller: _passwordController,
                obscureText: true, 
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre alanı boş bırakılamaz.';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre Tekrarı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre tekrarı boş bırakılamaz.';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor.'; 
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),
              
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kaydol'),
              ),
              
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                },
                child: const Text('Zaten hesabınız var mı? Giriş yapın.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}