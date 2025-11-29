import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/notifications_screen.dart'; // Bildirim sayfasına gitmek için

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox(); // Kullanıcı yoksa buton da yok

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false) // Okunmamışları say
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) count = snapshot.data!.docs.length;

        return IconButton(
          onPressed: () {
            // Bildirim Sayfasına Git
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
          icon: Badge(
            label: count > 0 ? Text("$count") : null, // Sayı 0 ise kırmızı nokta çıkmaz
            isLabelVisible: count > 0,
            backgroundColor: const Color(0xFFD32F2F), // Doğuş Kırmızısı
            child: const Icon(Icons.notifications_outlined, color: Colors.black87),
          ),
        );
      },
    );
  }
}