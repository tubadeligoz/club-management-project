import 'package:flutter/material.dart';

// SADECE SAYFALARI ÇAĞIRIYORUZ
import 'discover_screen.dart'; 
import 'home_screen.dart';     
import 'my_clubs_screen.dart'; 
import 'profile_screen.dart';  

class MainScaffold extends StatefulWidget {
  final String userRole;

  const MainScaffold({super.key, required this.userRole});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // Başlangıçta Keşfet (0) açık

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    // SAYFA SIRALAMASI
    _screens = [
      // 0. KEŞFET (VİTRİN)
      DiscoverScreen(onTabChange: _onItemTapped), 
      
      // 1. AKIŞ (SOSYAL MEDYA)
      HomeScreen(userRole: widget.userRole), 
      
      // 2. KULÜPLERİM
      const MyClubsScreen(),
      
      // 3. PROFİL
      ProfileScreen(userRole: widget.userRole),
    ];
  }

  // Sayfa Değiştirme Fonksiyonu
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.red.shade100, // Doğuş Kırmızısı tonu
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        
        destinations: const [
          // 1. KEŞFET
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: Color(0xFFD32F2F)),
            label: 'Keşfet',
          ),
          
          // 2. AKIŞ
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed, color: Color(0xFFD32F2F)),
            label: 'Akış',
          ),
          
          // 3. KULÜPLERİM
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars, color: Color(0xFFD32F2F)),
            label: 'Kulüplerim',
          ),
          
          // 4. PROFİL
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFD32F2F)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}