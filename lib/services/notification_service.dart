import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  
  // 1. KENDİNE BİLDİRİM AT (Mevcut)
  static Future<void> sendNotificationToSelf({required String title, required String body}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _saveToDatabase(user.uid, title, body);
    }
  }

  // 2. BAŞKASINA BİLDİRİM AT (YENİ - Adaylık Onayı İçin)
  static Future<void> sendNotificationToUser({required String userId, required String title, required String body}) async {
    await _saveToDatabase(userId, title, body);
  }

  // 3. TOPLU BİLDİRİM AT (YENİ - Post Paylaşımı İçin)
  static Future<void> sendNotificationToMultipleUsers({required List<dynamic> userIds, required String title, required String body}) async {
    // Döngüye alıp herkese tek tek atıyoruz (Gerçek hayatta Cloud Functions kullanılır ama bu proje için bu yeterli)
    for (String uid in userIds) {
      // Kendi kendine bildirim atmasın (Opsiyonel)
      if (uid != FirebaseAuth.instance.currentUser?.uid) {
        await _saveToDatabase(uid, title, body);
      }
    }
  }

  // Ortak Kayıt Fonksiyonu (Kod tekrarını önlemek için)
  static Future<void> _saveToDatabase(String uid, String title, String body) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'isRead': false,
          'date': FieldValue.serverTimestamp(),
        });
  }
}