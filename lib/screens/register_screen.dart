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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _allInterests = ["Yazılım", "Siber Güvenlik", "Yapay Zeka", "Müzik", "Tiyatro", "Spor", "Fotoğraf"];
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  // Kontroller
  bool _isEmailValid(String email) => email.endsWith('@dogus.edu.tr') || email.endsWith('@st.dogus.edu.tr');

  String? _validatePassword(String password) {
    if (password.length < 8) return "En az 8 karakter.";
    if (!password.contains(RegExp(r'[A-Z]'))) return "Büyük harf gerekli.";
    if (!password.contains(RegExp(r'[0-9]'))) return "Rakam gerekli.";
    return null;
  }

  Future<void> _register() async {
    if (!_isEmailValid(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sadece okul maili!")));
      return;
    }
    String? passError = _validatePassword(_passwordController.text.trim());
    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (cred.user != null) {
        await cred.user!.sendEmailVerification();
        
        // FİRESTORE KAYDI (VARSAYILAN ROL: OGRENCİ)
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'interests': _selectedInterests,
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
          'role': 'ogrenci', // <--- BURASI ÖNEMLİ
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text("Doğrulama Maili Gönderildi"),
              actions: [TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text("Giriş Yap"))],
            )
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Okul Maili", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              children: _allInterests.map((i) => FilterChip(label: Text(i), selected: _selectedInterests.contains(i), onSelected: (s) => setState(() => s ? _selectedInterests.add(i) : _selectedInterests.remove(i)))).toList()
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _register, child: _isLoading ? const CircularProgressIndicator() : const Text("Kayıt Ol"))
          ],
        ),
      ),
    );
  }
}