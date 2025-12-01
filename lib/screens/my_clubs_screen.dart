import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'club_detail_screen.dart';
import 'clubs_screen.dart'; 

class MyClubsScreen extends StatelessWidget {
  const MyClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Üye Olduğum Kulüpler"), centerTitle: true),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clubs')
            .where('members', arrayContains: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- BOŞ DURUM (Redundant Butonu Sildik) ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Henüz hiçbir kulübe üye değilsin.", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 5),
                  // Buton yerine yönlendirme yazısı
                  Text("Aşağıdaki butona basarak kulüpleri keşfet! 👇", 
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final clubs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              var club = clubs[index].data() as Map<String, dynamic>;
              String clubId = clubs[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(club['name'] ?? "İsimsiz"),
                  subtitle: const Text("Üyesiniz ✅"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClubDetailScreen(clubId: clubId, clubData: club)
                      )
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // --- TEK VE ANA BUTON BU ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const ClubsScreen())
          );
        },
        label: const Text("Tüm Kulüpler"),
        icon: const Icon(Icons.search),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}