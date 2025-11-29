import 'package:flutter/material.dart';
import 'dart:async'; // Zamanlayıcı için
import '../main.dart'; // Yönlendirme için

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;

  // Doğuş Kırmızısı (Yükleme çubuğu için)
  final Color _dogusRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();

    // 1. Animasyon Ayarları (Nefes Alma Efekti)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Logo hafifçe büyüyüp küçülecek (Canlılık hissi)
    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    
    // Animasyonu sürekli tekrar et
    _controller.repeat(reverse: true);

    // 2. Yönlendirme Zamanlayıcısı (3.5 saniye sonra)
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.stop(); // Geçiş yapmadan önce animasyonu durdur
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
    // Ekran genişliğini alıyoruz
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Arka plan TAM BEYAZ
      body: Stack(
        fit: StackFit.expand,
        children: [
          
          // --- MERKEZ KISIM (BÜYÜK LOGO) ---
          Center(
            child: ScaleTransition(
              scale: _logoScaleAnimation,
              child: Image.asset(
                'assets/icon-removebg-preview.png', // <--- SENİN ŞEFFAF DOSYAN
                width: screenWidth * 0.7, // Ekranın %70'i genişliğinde
                fit: BoxFit.contain,
                
                // --- ARTIK HİLE YOK (Kodlar Silindi) ---
                // color: Colors.white, (YOK)
                // colorBlendMode: BlendMode.multiply, (YOK)
                
                errorBuilder: (c,e,s) => Icon(Icons.school, size: 100, color: _dogusRed),
              ),
            ),
          ),

          // --- ALT KISIM (YÜKLEME & İMZA) ---
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Zarif Kırmızı Yükleme Çubuğu
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