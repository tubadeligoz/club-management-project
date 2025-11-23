import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. BURADA ÇAĞIRIYORUZ (Bu satır kalsın)
import 'club_detail_screen.dart'; 

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kampüs Kulüpleri"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz hiç kulüp yok."));
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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: (club['image'] != null && club['image'].isNotEmpty) 
                        ? NetworkImage(club['image']) 
                        : null,
                    child: (club['image'] == null) ? Text(club['name'][0]) : null,
                  ),
                  title: Text(club['name'] ?? "İsimsiz"),
                  subtitle: Text(club['description'] ?? ""),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  
                  // 2. İŞTE BURADA KULLANIYORUZ! 
                  // Bunu yazmazsan "Unused import" hatası alırsın.
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClubDetailScreen( // <--- BURASI ÖNEMLİ
                          clubId: clubId, 
                          clubData: club
                        )
                      )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}