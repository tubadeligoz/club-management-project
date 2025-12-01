import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart'; // Bildirim Servisi

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _clubNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _selectedImage;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // --- RESİM SEÇME ---
  Future<void> _pickImage() async {
    try {
      final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      
      // ASYNC GAP KONTROLÜ: İşlem bitince sayfa hala açık mı?
      if (!mounted) return;

      if (returnedImage == null) return;
      
      setState(() {
        _selectedImage = File(returnedImage.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim seçilemedi: $e")));
      }
    }
  }

  // --- TARİH SEÇME ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );

    // ASYNC GAP KONTROLÜ
    if (!mounted) return;

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- PAYLAŞMA VE BİLDİRİM ---
  Future<void> _sharePost() async {
    if (_clubNameController.text.isEmpty || _descriptionController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = "";

      // 1. Resim Yükleme (ImgBB)
      if (_selectedImage != null) {
        const String apiKey = "d1b71818d40c297e1f6f0dd345dba93b"; 
        final Uri url = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
        var request = http.MultipartRequest("POST", url);
        request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
        
        var response = await request.send();

        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final body = json.decode(respStr);
          imageUrl = body['data']['url'];
        }
      }

      // ASYNC GAP KONTROLÜ (Uzun süren yüklemeden sonra)
      if (!mounted) return;

      // 2. Postu Kaydetme
      await FirebaseFirestore.instance.collection('posts').add({
        'clubName': _clubNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'date': _selectedDate,
        'createdAt': FieldValue.serverTimestamp(),
        'likesList': [],
      });

      // 3. Bildirim Gönderme
      try {
        QuerySnapshot clubSnapshot = await FirebaseFirestore.instance
            .collection('clubs')
            .where('name', isEqualTo: _clubNameController.text.trim())
            .get();

        if (clubSnapshot.docs.isNotEmpty) {
          List members = clubSnapshot.docs.first.get('members') ?? [];
          if (members.isNotEmpty) {
            await NotificationService.sendNotificationToMultipleUsers(
              userIds: members, 
              title: "Yeni Etkinlik! 📢", 
              body: "${_clubNameController.text.trim()} yeni bir etkinlik paylaştı."
            );
          }
        }
      } catch (e) {
        debugPrint("Bildirim hatası: $e");
      }

      // SON KONTROL VE KAPATMA
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başarıyla Paylaşıldı! 🎉")));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Etkinlik Paylaş")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade400),
                  image: _selectedImage != null 
                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Fotoğraf Seç", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _clubNameController, 
              decoration: const InputDecoration(labelText: "Kulüp Adı", border: OutlineInputBorder(), prefixIcon: Icon(Icons.group))
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController, 
              maxLines: 3, 
              decoration: const InputDecoration(labelText: "Açıklama", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description))
            ),
            const SizedBox(height: 15),
            ListTile(
              title: Text(_selectedDate == null ? "Tarih Seçiniz" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
              trailing: const Icon(Icons.calendar_today, color: Colors.indigo),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sharePost,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 15)),
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.send, color: Colors.white),
              label: const Text("Etkinliği Paylaş", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}