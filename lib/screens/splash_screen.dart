import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // AuthWrapper'a gitmek için

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;

  // Doğuş Kırmızısı
  final Color _dogusRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();

    // 1. Animasyon Ayarları
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    
    _controller.repeat(reverse: true);

    // 2. Yönlendirme (3.5 saniye)
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          
          // --- MERKEZ KISIM ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Image.asset(
                    'assets/icon-removebg-preview.png', 
                    width: screenWidth * 0.6, 
                    fit: BoxFit.contain,
                    errorBuilder: (c,e,s) => Icon(Icons.school, size: 100, color: _dogusRed),
                  ),
                ),
                
                const SizedBox(height: 20),

                // 2. SLOGAN (KALINLAŞTIRILDI)
                const Text(
                  "Kampüsün Dijital Hali",
                  style: TextStyle(
                    color: Colors.black87, // Daha koyu, net siyah
                    fontSize: 20,          // Biraz büyüttük (18 -> 20)
                    fontWeight: FontWeight.w600, // <-- ARTIK DAHA KALIN (Semi-Bold)
                    letterSpacing: 1.2,
                    fontStyle: FontStyle.italic, 
                  ),
                ),
              ],
            ),
          ),

          // --- ALT KISIM ---
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    color: _dogusRed, 
                    strokeWidth: 3, // Çubuğu da biraz kalınlaştırdık
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "Developed by Doğuş Üniversitesi",
                  style: TextStyle(
                    color: Colors.grey.shade600, // Biraz daha koyu gri
                    fontSize: 13, // Biraz büyüttük
                    fontWeight: FontWeight.w500, // <-- BURASI DA KALINLAŞTI
                    letterSpacing: 1.1
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}