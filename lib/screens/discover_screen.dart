import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 

// Sayfalar ve Widgetlar
import 'clubs_screen.dart'; 
import 'calendar_screen.dart'; 
import '../services/ai_service.dart';
import '../widgets/notification_button.dart'; 

class DiscoverScreen extends StatefulWidget {
  final Function(int) onTabChange; 

  const DiscoverScreen({super.key, required this.onTabChange});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String aiResponse = "";
  bool isAiLoading = false;

  // --- SLAYT VERİLERİ ---
  final List<Map<String, dynamic>> _sliderData = [
    {
      'title': "Kampüsün Sesi 🎧",
      'subtitle': "Doğuş Top 50 - Şimdi Dinle",
      'colors': [const Color(0xFF1DB954), const Color(0xFF191414)], 
      'icon': Icons.play_circle_filled,
      'action': 'spotify',
      'bgImage': null, 
    },
    {
      // --- YENİ YILBAŞI KARTI ---
      'title': "Yılbaşı Partisi! 🎄",
      'subtitle': "Kardan adam, sıcak çikolata ve müzik!",
      // Yüklenmezse görünecek renkler: Kırmızı ve Çam Yeşili
      'colors': [const Color(0xFFD32F2F), const Color(0xFF1B5E20)], 
      'icon': Icons.ac_unit, // Kar tanesi ikonu
      'action': 'info',
      // Daha güvenilir bir kardan adam görseli
      'bgImage': 'https://images.unsplash.com/photo-1519068737630-e5db1b91bf4c?q=80&w=1000&auto=format&fit=crop',
    },
    {
      'title': "Günün Menüsü 🍔",
      'subtitle': "Mercimek, İzmir Köfte, Pilav",
      'colors': [const Color(0xFFD32F2F), const Color(0xFFFF5722)],
      'icon': Icons.restaurant_menu,
      'action': 'menu',
      'bgImage': null,
    },
    {
      'title': "Kariyer Günleri 💼",
      'subtitle': "Sektör liderleri kampüste!",
      'colors': [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      'icon': Icons.work,
      'action': 'info',
      'bgImage': null,
    },
  ];

  Future<void> _launchSpotify() async {
    final Uri url = Uri.parse("https://open.spotify.com/playlist/37i9dQZF1DX1HubL9D8Y0W"); 
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Link açılamadı';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spotify açılamadı.")));
      }
    }
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.restaurant, color: Colors.red), SizedBox(width: 10), Text("Günün Menüsü")]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• Süzme Mercimek Çorbası"), 
            Text("• İzmir Köfte / Püre"), 
            Text("• Pirinç Pilavı"), 
            Divider(), 
            Text("Kalori: 850 kcal", style: TextStyle(fontSize: 12, color: Colors.grey))
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kapat"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/appbar_logo.png', errorBuilder: (c,e,s)=>const Icon(Icons.school, color: Colors.red)),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("DOĞUŞ KULÜP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text("Kampüsü Keşfet", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey)),
          ],
        ),
        actions: [
          const NotificationButton(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey), 
            onPressed: () async => await FirebaseAuth.instance.signOut()
          )
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            
            // --- SLAYT ALANI ---
            CarouselSlider(
              options: CarouselOptions(
                height: 180.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                enlargeCenterPage: true,
                aspectRatio: 16/9,
                viewportFraction: 0.85,
              ),
              items: _sliderData.map((data) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        if (data['action'] == 'spotify') {
                          _launchSpotify();
                        } else if (data['action'] == 'menu') {
                          _showMenuDialog();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${data['title']} detayları yakında!")));
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        // 1. KATMAN: KARTIN ŞEKLİ VE GRADYAN RENGİ (ZEMİN)
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                          gradient: LinearGradient(
                            colors: data['colors'], // Kırmızı ve Yeşil burada
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        // 2. KATMAN: RESİM VE YAZILAR (STACK)
                        child: Stack(
                          children: [
                            // A. RESİM (Varsa arkaya döşe)
                            if (data['bgImage'] != null)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    data['bgImage'],
                                    fit: BoxFit.cover,
                                    // Resim yüklenemezse boş dön (Böylece alttaki Gradyan görünür, Gri değil!)
                                    errorBuilder: (c, e, s) => const SizedBox(),
                                  ),
                                ),
                              ),
                            
                            // B. KARARTMA PERDESİ (Yazı okunsun diye)
                            if (data['bgImage'] != null)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.black.withValues(alpha: 0.4), // %40 Karartma
                                  ),
                                ),
                              ),

                            // C. YAZILAR VE İKON (En Üstte)
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          data['title'], 
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontSize: 22, 
                                            fontWeight: FontWeight.w900,
                                            shadows: [Shadow(blurRadius: 10, color: Colors.black)]
                                          )
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          data['subtitle'], 
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontSize: 14, 
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(blurRadius: 5, color: Colors.black)]
                                          ), 
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                    child: Icon(data['icon'], color: Colors.white, size: 40)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // 2. HIZLI ERİŞİM
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Hızlı Erişim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 15),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMenuCard("Akış", "Güncel Postlar", Icons.dynamic_feed, Colors.orange, () => widget.onTabChange(1))), 
                      const SizedBox(width: 15),
                      Expanded(child: _buildMenuCard("Tüm Kulüpler", "Listeyi Gör", Icons.search, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_)=>const ClubsScreen())))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildMenuCard("Takvim", "Etkinlik Planı", Icons.calendar_month, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_)=>const CalendarScreen())))),
                      const SizedBox(width: 15),
                      Expanded(child: _buildMenuCard("AI Koç", "Sana Özel", Icons.psychology, Colors.teal, () => _showAiDialog(context))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 3. DUYURULAR
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Kampüs Duyuruları 📢", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ListView(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              padding: const EdgeInsets.all(10), 
              children: [
                _buildAnnouncementTile("Sınav Takvimi", "Vize tarihleri OBS sistemine yüklendi.", "1 saat önce"), 
                _buildAnnouncementTile("Kampüs Kartı", "Turnikelerde yeni sisteme geçiliyor.", "Dün"), 
                _buildAnnouncementTile("Kütüphane", "Final haftası 7/24 açık olacak.", "2 gün önce")
              ]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, 
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTile(String title, String sub, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10), 
      elevation: 0, 
      color: Colors.white, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), 
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.campaign, color: Colors.red)), 
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), 
        subtitle: Text(sub), 
        trailing: Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey))
      )
    );
  }

  void _showAiDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(children: [
            const Icon(Icons.psychology, size: 50, color: Colors.teal),
            const Text("Kampüs Asistanı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const Divider(),
            Expanded(child: SingleChildScrollView(child: Text(aiResponse.isEmpty ? "Senin ilgi alanlarına göre en iyi kulüpleri analiz etmemi ister misin? 👇" : aiResponse))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(15)),
              onPressed: isAiLoading ? null : () async {
                setModalState(() => isAiLoading = true);
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    AiService ai = AiService();
                    String response = await ai.getClubRecommendation(user.uid);
                    setModalState(() { aiResponse = response; isAiLoading = false; });
                  }
                } catch (e) { setModalState(() { aiResponse = "Hata: $e"; isAiLoading = false; }); }
              }, 
              icon: isAiLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(isAiLoading ? "Analiz Ediliyor..." : "Bana Öneri Yap", style: const TextStyle(color: Colors.white))
            )
          ]),
        )
      ),
    );
  }
}