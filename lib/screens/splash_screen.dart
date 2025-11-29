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

    // Nefes alma efekti
    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    _controller.repeat(reverse: true);


    // 2. Yönlendirme Zamanlayıcısı (3.5 saniye)
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
      // Arka plan rengi tam beyaz
      backgroundColor: Colors.white, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          
          // --- MERKEZ KISIM (LOGO) ---
          Center(
            child: ScaleTransition(
              scale: _logoScaleAnimation,
              child: Image.asset(
                'assets/icon.jpeg', // Senin dosyan
                width: screenWidth * 0.7, 
                fit: BoxFit.contain,
                
               
                color: Colors.white,
                colorBlendMode: BlendMode.multiply,
                // ----------------------------------

                errorBuilder: (c,e,s) => Icon(Icons.school, size: 100, color: _dogusRed),
              ),
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
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "Developed by Doğuş Üniversitesi",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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