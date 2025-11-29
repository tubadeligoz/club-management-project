import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  
  final List<String> _allInterests = [
    "Yazılım", "Siber Güvenlik", "Yapay Zeka", "Müzik", "Tiyatro", "Spor", "Fotoğraf"
  ];

  final List<String> _selected = [];
  bool _loading = false;

  bool _isEmailValid(String email) =>
      email.endsWith('@dogus.edu.tr') || email.endsWith('@st.dogus.edu.tr');

  String? _validatePassword(String password) {
    if (password.length < 8) return "En az 8 karakter";
    if (!password.contains(RegExp(r'[A-Z]'))) return "Büyük harf gerekli";
    if (!password.contains(RegExp(r'[0-9]'))) return "Rakam gerekli";
    return null;
  }

  Future<void> _register() async {
    if (!_isEmailValid(_email.text.trim())) {
      _showSnack("Sadece okul maili!");
      return;
    }

    final pError = _validatePassword(_password.text.trim());
    if (pError != null) {
      _showSnack(pError);
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      await cred.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'interests': _selected,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'role': 'ogrenci',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Doğrulama Maili Gönderildi"),
            content: const Text("Mailinizi kontrol edin"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text("Giriş Yap"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnack("Hata: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          children: [
            const SizedBox(height: 25),

            Text(
              "Hesap Oluştur",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Okul maili ile kayıt olup topluluğa katıl!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),

            // NAME
            _ModernField(
              controller: _name,
              label: "Ad Soyad",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // EMAIL
            _ModernField(
              controller: _email,
              label: "Okul Maili",
              icon: Icons.email,
            ),
            const SizedBox(height: 16),

            // PASSWORD
            _ModernField(
              controller: _password,
              label: "Şifre",
              icon: Icons.lock,
              obscure: true,
            ),
            const SizedBox(height: 20),

            Text(
              "İlgi Alanların",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allInterests.map((i) {
                final selected = _selected.contains(i);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selected ? _selected.remove(i) : _selected.add(i);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      i,
                      style: TextStyle(
                        color: selected ? Colors.blue.shade900 : Colors.grey.shade800,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // BUTTON
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Kayıt Ol", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
