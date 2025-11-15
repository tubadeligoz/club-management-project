import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GİRİŞ YAPMA METODU
  // ========================================================================
  Future<String?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        // Kullanıcı giriş yaptıktan sonra e-posta doğrulanmadıysa engelle
        await user.reload(); // En güncel e-posta doğrulama durumunu almak için
        if (!user.emailVerified) {
          await _auth.signOut(); // Doğrulanmamışsa oturumu kapat
          return 'Hesabınız aktif değil. Lütfen e-posta adresinize gönderilen doğrulama linkine tıklayın.';
        }
        
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('is_locked') && userData['is_locked'] == true) {
            // Kilitleme süresi kontrolü buraya eklenebilir. Şimdilik sadece kilitli olup olmadığını kontrol edelim.
            await _auth.signOut();
            return 'Hesabınız hatalı denemeler nedeniyle geçici olarak kilitlenmiştir. Lütfen daha sonra tekrar deneyin.'; // TD 2.5.1
        }
        
        // Giriş başarılıysa hatalı deneme sayacını sıfırlamak için
        await _db.collection('users').doc(user.uid).update({'failed_login_attempts': 0});
        
        return null; // Başarılı
      }
      return 'Giriş Başarısız.';
    } on FirebaseAuthException catch (e) {
      // Hatalı giriş senaryoları
      String? errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
        return 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
        case 'wrong-password':
        return 'Girdiğiniz şifre hatalı.';
        case 'invalid-email':
        return 'Girdiğiniz e-posta adresi geçerli değil.';
        default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';

}
      // Hatalı giriş denemelerini sayma ve engelleme mantığı
      try {
        final userRecord = await _auth.fetchSignInMethodsForEmail(email);
        if (userRecord.isNotEmpty) {
          final userQuery = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
          if (userQuery.docs.isNotEmpty) {
            final userDoc = userQuery.docs.first;
            int attempts = userDoc.data()['failed_login_attempts'] ?? 0;
            
            if (attempts >= 2) {
                await userDoc.reference.update({
                    'failed_login_attempts': attempts + 1,
                    'is_locked': true,
                    'locked_until': DateTime.now().add(const Duration(minutes: 30)) // TD 2.5.1
                });
                return 'Hesabınız 3 hatalı deneme nedeniyle 30 dakika süreyle kilitlenmiştir.';
            } else {
                await userDoc.reference.update({'failed_login_attempts': attempts + 1});
            }
          }
        }
      } catch (e) {
      }
      
      return errorMessage;
    }
  }

  // 📝 KAYIT OLMA METODU
  // ========================================================================
  Future<String?> register(String email, String password, String ad, String soyad) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification(); 
        
        await _db.collection('users').doc(user.uid).set({
          'ad': ad, 
          'soyad': soyad,
          'email': email,
          'failed_login_attempts': 0,
          'is_locked': false,
          'created_at': FieldValue.serverTimestamp(),
        });

      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      } else if (e.code == 'email-already-in-use') {
        return 'Bu e-posta adresi zaten kullanılıyor.';
      }
      return 'Kayıt sırasında bir hata oluştu.';
    }
  }
}