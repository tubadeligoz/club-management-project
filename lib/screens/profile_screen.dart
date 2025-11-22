import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final String userRole;
  const ProfileScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profilim"), centerTitle: true, automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50, 
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 50, color: Colors.white)
            ),
            const SizedBox(height: 20),
            
            Text(user?.email ?? "E-posta Yok", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            
            // Rolü gösteren etiket
            Chip(
              label: Text(userRole.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: userRole == 'baskan' ? Colors.red.shade100 : Colors.blue.shade100,
              avatar: Icon(userRole == 'baskan' ? Icons.star : Icons.school, size: 18),
            ),
            
            const SizedBox(height: 40),
            
            // ÇIKIŞ YAP BUTONU
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // main.dart'taki AuthWrapper otomatik olarak Login'e atacak
              },
              icon: const Icon(Icons.logout),
              label: const Text("Güvenli Çıkış"),
            )
          ],
        ),
      ),
    );
  }
}