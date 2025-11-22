import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _maxFailedAttempts = 3;
  static final Duration _lockDuration = const Duration(minutes: 30);

  Future<String?> signIn(String email, String password) async {
    email = email.trim();
    final now = DateTime.now();

    try {
      // Önce email ile kayıtlı kullanıcı varsa kilit durumunu kontrol et
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
            final minutesLeft = lockTime.difference(now).inMinutes;
            return 'Hesabınız hatalı denemeler nedeniyle $minutesLeft dakika daha kilitli. Lütfen daha sonra tekrar deneyin.';
          } else {
            // Kilit süresi dolmuşsa temizle
            await preQuery.docs.first.reference.update({
              'is_locked': false,
              'failed_login_attempts': 0,
              'locked_until': FieldValue.delete(),
            });
          }
        }
      }

      // Firebase Auth ile giriş denemesi
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

      // UID ile user dokümanını kontrol et ve deneme sayacını sıfırla
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
            final minutesLeft = lockTime.difference(now).inMinutes;
            await _auth.signOut();
            return 'Hesabınız hatalı denemeler nedeniyle $minutesLeft dakika daha kilitli. Lütfen daha sonra tekrar deneyin.';
          } else {
            await userDocRef.update({
              'is_locked': false,
              'failed_login_attempts': 0,
              'locked_until': FieldValue.delete(),
            });
          }
        } else {
          // Başarılı girişte sayaçları temizle
          await userDocRef.update({
            'failed_login_attempts': 0,
            'is_locked': false,
            'locked_until': FieldValue.delete(),
          });
        }
      }

      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Girdiğiniz şifre hatalı.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Girdiğiniz e-posta adresi geçerli değil.';
      }

      // Hatalı giriş denemelerini sayma ve gerektiğinde kilitleme
      try {
        final userQuery = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
        if (userQuery.docs.isNotEmpty) {
          final doc = userQuery.docs.first;
          final data = doc.data();
          int attempts = 0;
          final raw = data['failed_login_attempts'];
          if (raw is int) {
            attempts = raw;
          } else if (raw is String) {
            attempts = int.tryParse(raw) ?? 0;
          }

          final newAttempts = attempts + 1;

          if (newAttempts >= _maxFailedAttempts) {
            final lockedUntilTs = Timestamp.fromDate(now.add(_lockDuration));
            await doc.reference.update({
              'failed_login_attempts': newAttempts,
              'is_locked': true,
              'locked_until': lockedUntilTs,
            });
            return 'Hesabınız $_maxFailedAttempts hatalı deneme nedeniyle ${_lockDuration.inMinutes} dakika süreyle kilitlenmiştir.';
          } else {
            await doc.reference.update({'failed_login_attempts': newAttempts});
          }
        }
      } catch (_) {
        // Firestore güncellemesi başarısız olursa sessizce geç
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