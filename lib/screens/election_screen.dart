import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart'; // Bildirim servisini çağırıyoruz

class ElectionScreen extends StatefulWidget {
  final String electionId;
  final String clubName;

  const ElectionScreen({super.key, required this.electionId, required this.clubName});

  @override
  State<ElectionScreen> createState() => _ElectionScreenState();
}

class _ElectionScreenState extends State<ElectionScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (currentUser != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'ogrenci';
        });
      }
    }
  }

  // --- ADAY OLMA ---
  Future<void> _becomeCandidate() async {
    TextEditingController sloganController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Adaylık Başvurusu 📝"),
        content: TextField(
          controller: sloganController,
          decoration: const InputDecoration(labelText: "Seçim Vaadin"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Dialogu kapat
              
              DocumentReference ref = FirebaseFirestore.instance.collection('elections').doc(widget.electionId);
              
              Map<String, dynamic> newCandidate = {
                'uid': currentUser!.uid,
                'name': currentUser!.email!.split('@')[0],
                'slogan': sloganController.text,
                'voteCount': 0,
                'isApproved': false,
              };

              await ref.update({
                'candidates': FieldValue.arrayUnion([newCandidate])
              });

              // İşlem bitti, sayfa hala açık mı?
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başvuru yapıldı! Danışman onayı bekleniyor.")));
            },
            child: const Text("Başvur"),
          )
        ],
      ),
    );
  }

  // --- DANIŞMAN ONAY/RET (BİLDİRİM EKLENDİ) ---
  Future<void> _approveCandidate(Map<String, dynamic> candidate, bool isApproved) async {
    DocumentReference ref = FirebaseFirestore.instance.collection('elections').doc(widget.electionId);

    // 1. Önce eski halini listeden sil
    await ref.update({
      'candidates': FieldValue.arrayRemove([candidate])
    });

    if (isApproved) {
      // 2. Onaylandıysa: isApproved = true yapıp geri ekle
      candidate['isApproved'] = true;
      await ref.update({
        'candidates': FieldValue.arrayUnion([candidate])
      });

      // --- BİLDİRİM GÖNDER (Kabul) ---
      await NotificationService.sendNotificationToUser(
        userId: candidate['uid'], // Öğrencinin ID'si
        title: "Adaylığın Onaylandı! ✅",
        body: "${widget.clubName} için başkanlık başvurunu danışman onayladı. Başarılar!",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aday Onaylandı ve Bildirim Gönderildi ✅")));
    
    } else {
      // Reddedildiyse geri eklemiyoruz (Listeden silinmiş oluyor)
      
      // --- BİLDİRİM GÖNDER (Ret) ---
      await NotificationService.sendNotificationToUser(
        userId: candidate['uid'],
        title: "Başvuru Durumu ❌",
        body: "${widget.clubName} başkanlık başvurunu maalesef onaylanmadı.",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aday Reddedildi ve Bildirildi ❌")));
    }
  }

  // --- OY VERME ---
  Future<void> _voteForCandidate(Map<String, dynamic> candidate) async {
    DocumentReference ref = FirebaseFirestore.instance.collection('elections').doc(widget.electionId);

    await ref.update({'candidates': FieldValue.arrayRemove([candidate])});
    
    int currentVotes = candidate['voteCount'] ?? 0;
    candidate['voteCount'] = currentVotes + 1;
    
    await ref.update({
      'candidates': FieldValue.arrayUnion([candidate]),
      'voters': FieldValue.arrayUnion([currentUser!.uid])
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oy kullanıldı!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.clubName} Seçimi")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('elections').doc(widget.electionId).snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Seçim verisi yok."));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          // Veri Güvenliği
          List rawCandidates = [];
          List voters = [];
          try {
             rawCandidates = List.from(data['candidates'] ?? []);
             voters = List.from(data['voters'] ?? []);
          } catch(e) {
             return const Center(child: Text("HATA: Veritabanı yapısı bozuk (Array bekleniyor)."));
          }

          // Map Dönüşümü
          var allCandidates = rawCandidates.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          var approved = allCandidates.where((c) => c['isApproved'] == true).toList();
          var pending = allCandidates.where((c) => c['isApproved'] != true).toList();

          bool hasVoted = voters.contains(currentUser!.uid);
          
          Map<String, dynamic>? myApplication;
          try {
            myApplication = allCandidates.firstWhere((c) => c['uid'] == currentUser!.uid);
          } catch (e) {
            myApplication = null;
          }

          return Column(
            children: [
              // BAŞLIK
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                color: Colors.indigo.shade50,
                child: Column(
                  children: [
                    Text(data['title'] ?? "Seçim", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (hasVoted) const Chip(label: Text("Oyunuzu Kullandınız ✅"), backgroundColor: Colors.greenAccent),
                  ],
                ),
              ),

              // DANIŞMAN PANELİ
              if (userRole == 'danisman' && pending.isNotEmpty)
                Container(
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      const Text("Onay Bekleyenler", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...pending.map((c) => ListTile(
                        title: Text(c['name']),
                        subtitle: Text("Vaat: ${c['slogan']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green), 
                              onPressed: () => _approveCandidate(c, true)
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red), 
                              onPressed: () => _approveCandidate(c, false)
                            ),
                          ],
                        ),
                      ))
                    ],
                  ),
                ),

              // ONAYLI LİSTE
              Expanded(
                child: approved.isEmpty
                    ? const Center(child: Text("Henüz onaylı aday yok."))
                    : ListView.builder(
                        itemCount: approved.length,
                        itemBuilder: (context, index) {
                          var c = approved[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(child: Text("${c['voteCount']}")),
                              title: Text(c['name']),
                              subtitle: Text(c['slogan']),
                              trailing: (!hasVoted && userRole != 'danisman')
                                  ? ElevatedButton(onPressed: () => _voteForCandidate(c), child: const Text("OY VER"))
                                  : const Icon(Icons.lock, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),

              // --- BUTONLAR ---
              if (userRole != 'danisman' && !hasVoted)
                if (myApplication == null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _becomeCandidate,
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text("BAŞKANLIĞA ADAY OL", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  )
                else if (myApplication['isApproved'] != true)
                  Container(
                    padding: const EdgeInsets.all(15),
                    color: Colors.yellow.shade100,
                    width: double.infinity,
                    child: const Column(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange),
                        Text("BAŞVURUNUZ ALINDI!\nDanışman onayı bekleniyor.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else if (hasVoted)
                   Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text("Katılımınız için teşekkürler! 🗳️", style: TextStyle(color: Colors.grey)),
                    )
            ],
          );
        },
      ),
    );
  }
}