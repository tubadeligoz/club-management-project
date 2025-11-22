import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_key.dart';

class AiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
  }

  Future<String> getClubRecommendation(String userId) async {
    try {
      // 1. Verileri Çek
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return "Hata: Kullanıcı bulunamadı ($userId)";
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> interests = userData['interests'] ?? []; 
      
      // YENİ: Kullanıcının ismini çekiyoruz (Yoksa 'Dostum' diyecek)
      String userName = userData['name'] ?? 'Dostum';

      QuerySnapshot clubsSnapshot = await _firestore.collection('clubs').get();
      String clubsText = "";
      for (var doc in clubsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        clubsText += "- ${data['name']} (Etiketler: ${data['tags']})\n";
      }

      // 2. Prompt Hazırla (Samimi Koç Modu 🚀)
      String prompt = """
      Sen üniversite kampüsünün en sevilen, enerjik ve samimi öğrenci koçusun.
      Asla sıkıcı veya robot gibi konuşma. Bir abi/abla veya yakın bir arkadaş gibi konuş.
      Bol bol emoji kullan (🚀, 🎸, 💻, 🔥 gibi).

      HEDEF KİTLE:
      Öğrencinin Adı: $userName
      İlgi Alanları: ${interests.join(", ")}

      OKULDAKİ KULÜPLER:
      $clubsText

      GÖREVİN:
      1. Öğrenciye ismiyle hitap ederek sıcak bir giriş yap ("Selam $userName! 👋" gibi).
      2. İlgi alanlarına bakarak nokta atışı 1 tane kulüp öner.
      3. Neden bu kulübü seçtiğini "Çünkü sen..." diyerek onun ilgi alanlarıyla bağdaştır.
      4. Cevabı kısa bir paragraf olarak yaz, okuması keyifli olsun.
      5. Motive edici kısa bir sözle bitir.
      """;

      // 3. Gönder ve Cevapla
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "Şu an ilham perilerim gelmedi, tekrar dener misin? 🤔";
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }
}