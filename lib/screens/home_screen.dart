import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';
import '../widgets/notification_button.dart'; // Bildirim butonu
import 'add_post_screen.dart';
import 'comments_sheet.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

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
        title: Text(
          widget.userRole == 'baskan' ? "Başkan Paneli" : "Kampüs Akışı",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          // BİLDİRİM BUTONU
          const NotificationButton(),
          
          // ÇIKIŞ BUTONU
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      
      // --- FEED ---
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
                  const Text("Akış boş."),
                  if (widget.userRole == 'baskan')
                    const Text("Hadi paylaşım yap Başkan!", style: TextStyle(color: Color(0xFFD32F2F))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return PostCard(
                postDoc: snapshot.data!.docs[index], 
                userRole: widget.userRole
              );
            },
          );
        },
      ),

      // --- BUTONLAR ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.userRole == 'baskan')
            FloatingActionButton(
              heroTag: "add",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen())),
              backgroundColor: const Color(0xFFD32F2F), // Kırmızı
              child: const Icon(Icons.add, color: Colors.white),
            ),
          
          const SizedBox(height: 15),

          FloatingActionButton.extended(
            heroTag: "ai",
            onPressed: _showAiDialog,
            backgroundColor: const Color(0xFFD32F2F), // Kırmızı
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text("AI Asistan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAiDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(children: [
            const Icon(Icons.psychology, size: 50, color: Color(0xFFD32F2F)),
            const Text("Kulüp Koçun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const Divider(),
            Expanded(child: SingleChildScrollView(child: Text(aiResponse.isEmpty ? "Analiz için butona bas!" : aiResponse))),
            ElevatedButton(
              onPressed: isAiLoading ? null : () async {
                setModalState(() => isAiLoading = true);
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    String response = await AiService().getClubRecommendation(user.uid);
                    setModalState(() { aiResponse = response; isAiLoading = false; });
                  }
                } catch (e) { setModalState(() { aiResponse = "Hata: $e"; isAiLoading = false; }); }
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              child: const Text("Bana Kulüp Öner", style: TextStyle(color: Colors.white))
            )
          ]),
        )
      ),
    );
  }
}

// --- MODERN POST KARTI ---
class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot postDoc;
  final String userRole;

  const PostCard({super.key, required this.postDoc, required this.userRole});

  Future<void> _toggleLike() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    DocumentReference ref = FirebaseFirestore.instance.collection('posts').doc(postDoc.id);
    Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
    List likes = List.from(data['likesList'] ?? []);
    if (likes.contains(user.uid)) {
      await ref.update({'likesList': FieldValue.arrayRemove([user.uid])});
    } else {
      await ref.update({'likesList': FieldValue.arrayUnion([user.uid])});
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
    User? user = FirebaseAuth.instance.currentUser;
    List likes = List.from(data['likesList'] ?? []);
    bool isLiked = likes.contains(user?.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAŞLIK
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red.shade50,
                  child: Text(
                    data['clubName'] != null ? data['clubName'][0] : "?",
                    style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['clubName'] ?? "Kulüp", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Yakın zamanda", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                if (userRole == 'baskan') 
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey), 
                    onPressed: () => FirebaseFirestore.instance.collection('posts').doc(postDoc.id).delete()
                  ),
              ],
            ),
          ),

          // GÖRSEL
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  data['imageUrl'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(height: 200, color: Colors.grey.shade100, child: const Icon(Icons.broken_image)),
                ),
              ),
            ),

          // AÇIKLAMA
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: Text(
              data['description'] ?? "",
              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
            ),
          ),

          // BUTONLAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? const Color(0xFFFF5252) : Colors.black54,
                    size: 28,
                  ),
                ),
                Text("${likes.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                
                const SizedBox(width: 15),
                
                IconButton(
                  onPressed: () => showModalBottomSheet(
                    context: context, 
                    isScrollControlled: true, 
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentsSheet(postId: postDoc.id)
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54, size: 26),
                ),
                const Text("Yorum", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}