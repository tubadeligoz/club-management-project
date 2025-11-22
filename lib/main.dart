import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'screens/login_screen.dart'; 

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
    print("Firebase başarıyla başlatıldı.");
  } catch (e) {
    // Eğer başlatma başarısız olursa (örneğin, bir platformun ayar dosyası eksikse)
    print("HATA: Firebase başlatılamadı. Lütfen Firebase yapılandırmasını kontrol edin. Hata detayı: $e");
    // Uygulamanın yine de açılabilmesi için devam ediyoruz, 
    // ancak Firebase gerektiren özellikler çalışmayacaktır.
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doğuş Üniversitesi Kulüp Uygulaması',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}