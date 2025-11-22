import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';

// DİKKAT: Artık HomeScreen'i değil, MainScaffold'ı çağırıyoruz
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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const AuthWrapper(), 
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
        // 1. Bağlantı Bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Kullanıcı Giriş Yapmışsa
        if (snapshot.hasData) {
          User? user = snapshot.data;

          // Mail onaylı mı?
          if (user != null && user.emailVerified) {
            
            // --- ROL SORGULAMA ---
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, roleSnapshot) {
                
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                String role = 'ogrenci'; // Varsayılan rol

                if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                  Map<String, dynamic> data = roleSnapshot.data!.data() as Map<String, dynamic>;
                  role = data['role'] ?? 'ogrenci';
                  
                  debugPrint("---------------------------------------");
                  debugPrint("GİRİŞ YAPAN: ${user.email}");
                  debugPrint("ROLÜ: $role");
                  debugPrint("---------------------------------------");
                }

                // --- İŞTE BURAYI DEĞİŞTİRDİK ---
                // Eskisi: return HomeScreen(userRole: role);
                // Yenisi: MainScaffold (Alt Menülü Çatı)
                return MainScaffold(userRole: role);
                // -------------------------------
              },
            );

          } else {
            // Mail onaysızsa Login
            return const LoginScreen();
          }
        }

        // 3. Kimse yoksa Login
        return const LoginScreen();
      },
    );
  }
}