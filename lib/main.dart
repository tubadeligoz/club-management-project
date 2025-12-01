import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// SAYFALAR
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doğuş Kulüp AI',
      
      // --- MODERN KIRMIZI-BEYAZ TEMA ---
      theme: ThemeData(
        useMaterial3: true,
        
        // RENK PALETİ
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F), // Doğuş Kırmızısı
          primary: const Color(0xFFD32F2F),   
          secondary: const Color(0xFFB71C1C), 
          surface: Colors.white,              
          onPrimary: Colors.white,            
        ),

        // YAZI TİPİ
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

        // APP BAR
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFFD32F2F), 
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFFD32F2F)),
          titleTextStyle: TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ALT MENÜ (DÜZELTİLEN KISIM BURASI)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.red.shade100,
          
          // ESKİSİ: MaterialStateProperty.all(...)
          // YENİSİ: WidgetStateProperty.all(...)
          iconTheme: WidgetStateProperty.all(const IconThemeData(color: Color(0xFFD32F2F))),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))
          ),
        ),

        // BUTON
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,            
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
        
        // INPUT KUTULARI
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          prefixIconColor: Colors.grey,
        ),
      ),

      home: const SplashScreen(), 
    );
  }
}

// --- TRAFİK POLİSİ (AuthWrapper) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          User? user = snapshot.data;

          if (user != null && user.emailVerified) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, roleSnapshot) {
                
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                String role = 'ogrenci'; 

                if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                  Map<String, dynamic> data = roleSnapshot.data!.data() as Map<String, dynamic>;
                  role = data['role'] ?? 'ogrenci';
                  debugPrint("GİRİŞ YAPAN: ${user.email} | ROLÜ: $role");
                }

                return MainScaffold(userRole: role);
              },
            );
          } else {
            return const LoginScreen();
          }
        }
        return const LoginScreen();
      },
    );
  }
}