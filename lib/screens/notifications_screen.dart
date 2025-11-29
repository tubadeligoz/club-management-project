import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Tarih formatı için

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Bildirimler"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        // users/{uid}/notifications koleksiyonunu dinliyoruz
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('notifications')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Hiç bildiriminiz yok."),
                ],
              ),
            );
          }

          final notifs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              var notif = notifs[index];
              var data = notif.data() as Map<String, dynamic>;
              bool isRead = data['isRead'] ?? false;

              // --- KAYDIRARAK SİLME (SWIPE TO DELETE) ---
              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart, // Sağa kaydır
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  // Veritabanından sil
                  notif.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bildirim silindi")));
                },
                child: Container(
                  color: isRead ? Colors.white : Colors.blue.shade50, // Okunmamışsa mavi arka plan
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey : Colors.blue,
                      child: Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(
                      data['title'] ?? "Bildirim",
                      style: TextStyle(
                        // OKUNMAMIŞSA KALIN YAZI
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['body'] ?? ""),
                        const SizedBox(height: 5),
                        Text(
                          data['date'] != null 
                            ? DateFormat('dd/MM HH:mm').format((data['date'] as Timestamp).toDate())
                            : "",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        )
                      ],
                    ),
                    onTap: () {
                      // Tıklayınca "Okundu" olarak işaretle
                      notif.reference.update({'isRead': true});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}