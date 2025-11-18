import 'package:club_management_project/screens/register_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// import 'register_screen.dart'; // Kayıt ekranına geçiş için
// import 'home_screen.dart'; // Başarılı girişte yönlendirilecek ekran

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ogrNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ogrNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authService = AuthService();
      String email = _ogrNoController.text.trim();
      
      String? errorMessage = await authService.signIn(
        email,
        _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı!'), backgroundColor: Colors.green),
        );
      } else {

        String displayMessage = errorMessage;
        if (errorMessage.contains('Şifre hatalı')) {
          displayMessage = 'Kullanıcı Şifresi Hatalı.';
        } else if (errorMessage.contains('Kullanıcı bulunamadı')) {
          displayMessage = 'Kullanıcı Adı Hatalı.';
        } else if (errorMessage.contains('Kilitlenmiştir')) {
           displayMessage = errorMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: displayMessage.contains('Kilitlenmiştir') ? Colors.blue : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 50),

                  TextFormField(
                    controller: _ogrNoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Öğrenci Numarası / E-posta'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bu alan boş bırakılamaz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre alanı boş bırakılamaz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Giriş Yap'),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text('Hesabınız yok mu? Kaydolun.'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}