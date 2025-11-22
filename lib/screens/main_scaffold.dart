import 'package:flutter/material.dart';
import 'home_screen.dart';   // Akış Sayfası
import 'clubs_screen.dart';  // Kulüpler Sayfası
import 'profile_screen.dart'; // Profil Sayfası (Aşağıda vereceğim)


class MainScaffold extends StatefulWidget {
  final String userRole; // Rolü buradan alıp diğer sayfalara dağıtacağız

  const MainScaffold({super.key, required this.userRole});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // Başlangıçta 0. sayfa (Akış) açık

  // Sayfaların listesi
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Sayfaları listeye ekliyoruz
    _screens = [
      HomeScreen(userRole: widget.userRole), // 0: Akış
      const ClubsScreen(),                   // 1: Kulüpler
      ProfileScreen(userRole: widget.userRole), // 2: Profil
    ];
  }

  // Tıklanınca çalışan fonksiyon
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BODY: O an seçili olan sayfayı gösterir
      body: _screens[_selectedIndex],

      // ALT MENÜ (Bottom Navigation Bar)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.indigo.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed, color: Colors.indigo),
            label: 'Akış',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Colors.indigo),
            label: 'Kulüpler',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.indigo),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}