import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart'; // AI Servisi import


class HomeScreen extends StatefulWidget {
  final String userRole; // Rol bilgisini dışarıdan alıyoruz

  const HomeScreen({super.key, this.userRole = 'ogrenci'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String aiResponse = "";
  bool isAiLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // Başkana özel başlık
        title: Text(
          widget.userRole == 'baskan' ? "Başkan Paneli 👑" : "Kampüs Akışı",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      
      // --- SOSYAL AKIŞ (FEED) ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dynamic_feed, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Henüz hiç etkinlik paylaşılmamış."),
                  if (widget.userRole == 'baskan')
                    const Text("İlk paylaşımı sen yap Başkan! 👇", style: TextStyle(color: Colors.indigo)),
                ],
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index].data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(post['clubName'] != null ? post['clubName'][0] : "?"),
                      ),
                      title: Text(post['clubName'] ?? "Kulüp", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Yakın zamanda"),
                      trailing: widget.userRole == 'baskan' 
                          ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: (){
                              // İleride silme kodu gelecek
                            }) 
                          : null,
                    ),
                    if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
                      Image.network(
                        post['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const SizedBox(),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(post['description'] ?? ""),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // --- BUTONLAR (YETKİYE GÖRE) ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. SADECE BAŞKAN GÖRÜR
          if (widget.userRole == 'baskan')
            FloatingActionButton(
              heroTag: "add_post",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post Ekleme Sayfası Açılacak...")));
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          
          const SizedBox(height: 15),

          // 2. HERKES GÖRÜR (AI)
          FloatingActionButton.extended(
            heroTag: "ai_chat",
            onPressed: _showAiDialog,
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text("AI Asistan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // AI PENCERESİ
  void _showAiDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 500,
              child: Column(
                children: [
                  const Icon(Icons.psychology, size: 50, color: Colors.indigo),
                  const SizedBox(height: 10),
                  const Text("Kulüp Koçun", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        aiResponse.isEmpty ? "Analiz için butona bas! 👇" : aiResponse,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.all(15)),
                      onPressed: isAiLoading ? null : () async {
                        setModalState(() => isAiLoading = true);
                        try {
                          User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            AiService ai = AiService();
                            String response = await ai.getClubRecommendation(user.uid);
                            setModalState(() {
                              aiResponse = response;
                              isAiLoading = false;
                            });
                          }
                        } catch (e) {
                          setModalState(() { aiResponse = "Hata: $e"; isAiLoading = false; });
                        }
                      },
                      icon: isAiLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.search, color: Colors.white),
                      label: Text(isAiLoading ? "Düşünüyor..." : "Bana Kulüp Öner", style: const TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }
}