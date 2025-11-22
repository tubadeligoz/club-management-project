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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (cred.user != null) {
        if (!cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen mailini doğrula!")));
          return;
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giriş Başarısız. Bilgileri kontrol et.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30), // Biraz daha fazla padding ekledik
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Image.asset yapısı ve height özelliği doğru şekilde birleştirildi.
              Image.asset(
                'assets/images/DogusLogo.png', 
                height: 150,
              ),
              const SizedBox(height: 40), // Logonun altındaki boşluğu artırdık
              
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder())
              ),
              const SizedBox(height: 10),
              
              TextField(
                controller: _passwordController, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder())
              ),
              const SizedBox(height: 20),
              
              // Giriş Yap Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _login, 
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.red),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Giriş Yap", style: TextStyle(color: Colors.white))
              ),
              
              // Kayıt Ol Butonu
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Kayıt Ol"),
              )
            ],
          ),
        ),
      ),
    );
  }
}