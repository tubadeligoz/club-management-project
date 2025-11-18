import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<String?> signIn(String email, String password) async {
    email = email.trim();
    final now = DateTime.now();

    try {

      final preQuery = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (preQuery.docs.isNotEmpty) {
        final data = preQuery.docs.first.data();
        final isLocked = data['is_locked'] == true;
        final lockedUntil = data['locked_until'];

        if (isLocked && lockedUntil != null) {
          DateTime lockTime;
          if (lockedUntil is Timestamp) {
            lockTime = lockedUntil.toDate();
          } else if (lockedUntil is DateTime) {
            lockTime = lockedUntil;
          } else {
            lockTime = DateTime.fromMillisecondsSinceEpoch(0);
          }

          if (lockTime.isAfter(now)) {
            return 'Hesabınız hatalı denemeler nedeniyle geçici olarak kilitlenmiştir. Lütfen daha sonra tekrar deneyin.';
          } else {

            await preQuery.docs.first.reference.update({
              'is_locked': false,
              'failed_login_attempts': 0,
              'locked_until': FieldValue.delete(),
            });
          }
        }
      }


      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        return 'Giriş Başarısız.';
      }

      await user.reload();
      if (!user.emailVerified) {
        await _auth.signOut();
        return 'Hesabınız aktif değil. Lütfen e-posta adresinize gönderilen doğrulama linkine tıklayın.';
      }


      final userDocRef = _db.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final isLocked = userData['is_locked'] == true;
        final lockedUntil = userData['locked_until'];

        if (isLocked && lockedUntil != null) {
          DateTime lockTime;
          if (lockedUntil is Timestamp) {
            lockTime = lockedUntil.toDate();
          } else if (lockedUntil is DateTime) {
            lockTime = lockedUntil;
          } else {
            lockTime = DateTime.fromMillisecondsSinceEpoch(0);
          }

          if (lockTime.isAfter(now)) {
            await _auth.signOut();
            return 'Hesabınız hatalı denemeler nedeniyle geçici olarak kilitlenmiştir. Lütfen daha sonra tekrar deneyin.';
          } else {
            await userDocRef.update({
              'is_locked': false,
              'failed_login_attempts': 0,
              'locked_until': FieldValue.delete(),
            });
          }
        } else {
          await userDocRef.update({'failed_login_attempts': 0, 'is_locked': false});
        }
      }

      return null; 
    } on FirebaseAuthException catch (e) {

      String errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Girdiğiniz şifre hatalı.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Girdiğiniz e-posta adresi geçerli değil.';
      }


      try {
        final userQuery = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
        if (userQuery.docs.isNotEmpty) {
          final doc = userQuery.docs.first;
          final data = doc.data();
          int attempts = 0;
          final raw = data['failed_login_attempts'];
          if (raw is int) {
            attempts = raw;
          } else if (raw is String) attempts = int.tryParse(raw) ?? 0;

          if (attempts >= 2) {
            await doc.reference.update({
              'failed_login_attempts': attempts + 1,
              'is_locked': true,
              'locked_until': Timestamp.fromDate(now.add(const Duration(minutes: 30))),
            });
            return 'Hesabınız 3 hatalı deneme nedeniyle 30 dakika süreyle kilitlenmiştir.';
          } else {
            await doc.reference.update({'failed_login_attempts': attempts + 1});
          }
        }
      } catch (_) {

      }

      return errorMessage;
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: ${e.toString()}';
    }
  }


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
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: ${e.toString()}';
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }


  User? getCurrentUser() => _auth.currentUser;
}