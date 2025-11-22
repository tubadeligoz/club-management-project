import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'election_screen.dart'; 

class ClubDetailScreen extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic> clubData;

  const ClubDetailScreen({super.key, required this.clubId, required this.clubData});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isMember = false;
  int memberCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkMembership();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkMembership() {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    List members = widget.clubData['members'] ?? [];
    setState(() {
      isMember = members.contains(myUid);
      memberCount = members.length;
    });
  }

  Future<void> _toggleMembership() async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference clubRef = FirebaseFirestore.instance.collection('clubs').doc(widget.clubId);

    try {
      if (isMember) {
        await clubRef.update({
          'members': FieldValue.arrayRemove([myUid])
        });
        setState(() {
          isMember = false;
          memberCount--;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kulüpten ayrıldın.")));
      } else {
        await clubRef.update({
          'members': FieldValue.arrayUnion([myUid])
        });
        setState(() {
          isMember = true;
          memberCount++;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tebrikler! Kulübe katıldın. 🎉")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.clubData['name'] ?? "Kulüp",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
                background: Image.network(
                  widget.clubData['image'] ?? "https://picsum.photos/500/300",
                  fit: BoxFit.cover,
                  // YENİ FLUTTER SÜRÜMÜ UYUMLU:
                  color: Colors.black.withValues(alpha: 0.3),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$memberCount Üye", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const Text("Aktif Kulüp", style: TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _toggleMembership,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMember ? Colors.grey : Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(isMember ? "Üyesin" : "Üye Ol", style: const TextStyle(color: Colors.white)),
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    // SEÇİM BUTONU
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('elections')
                          .where('clubId', isEqualTo: widget.clubId)
                          .where('isActive', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        var election = snapshot.data!.docs.first;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 15),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.orange.shade900,
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ElectionScreen(
                                    electionId: election.id,
                                    clubName: widget.clubData['name'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.how_to_vote),
                            label: Text("Seçim Var: ${election['title']}"),
                          ),
                        );
                      },
                    ),

                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: "Etkinlikler"),
                        Tab(text: "Hakkında"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        // --- GÖVDE KISMI ---
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsTab(), // 1. Fonksiyonu çağırıyoruz
            _buildAboutTab(),  // 2. Fonksiyonu çağırıyoruz (HATA BURADAYDI)
          ],
        ),
      ),
    );
  }

  // --- İŞTE EKSİK OLAN ALT KISIMLAR BURADA ---

  Widget _buildEventsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('clubName', isEqualTo: widget.clubData['name'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz etkinlik paylaşılmamış."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.indigo),
                title: Text(post['description'] ?? ""),
                subtitle: const Text("Yakın zamanda"),
              ),
            );
          },
        );
      },
    );
  }

  // EKSİK OLAN FONKSİYON BU:
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kulüp Hakkında", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Text(widget.clubData['description'] ?? "Açıklama girilmemiş.", style: const TextStyle(fontSize: 16, height: 1.5)),

          const SizedBox(height: 30),
          const Text("Yönetim", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text("Kulüp Başkanı"),
            subtitle: Text(widget.clubData['presidentUID'] ?? "Atanmamış"),
          ),
          const Divider(),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mail),
              label: const Text("iletisim@kulup.dogus.edu.tr"),
            ),
          )
        ],
      ),
    );
  }
}