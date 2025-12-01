import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String userRole;
  const ProfileScreen({super.key, required this.userRole});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _deptController = TextEditingController(); 
  
  bool _isEditing = false; 
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? "";
        _bioController.text = data['bio'] ?? "";
        _deptController.text = data['department'] ?? "";
      });
    }
  }

  Future<void> _pickImage() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        const String apiKey = "d1b71818d40c297e1f6f0dd345dba93b"; // Key
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

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'department': _deptController.text.trim(),
      };

      if (imageUrl != null) {
        updateData['photoUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update(updateData);

      setState(() {
        _isEditing = false;
        _selectedImage = null; 
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil Güncellendi! ✅")));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer kullanıcı oturumu yoksa, hata vereceği yerde güvenli bir görünüm göster
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sosyal Transkript"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text("Lütfen giriş yapın.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sosyal Transkript"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // YÜKLENİYOR MU?
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            // DÜZENLEME BUTONLARI (Edit / Save)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.indigo),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
          
          // --- ÇIKIŞ YAP BUTONU (BURAYA TAŞINDI) ---
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
          // -----------------------------------------
        ],
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docSnapshot = snapshot.data;
          if (docSnapshot == null || !docSnapshot.exists) {
            return const Center(child: Text("Kullanıcı bulunamadı"));
          }

          final userData = (docSnapshot.data() as Map<String, dynamic>?) ?? {};
          final String name = (userData['name'] ?? '').toString();
          final String photoUrl = (userData['photoUrl'] ?? '').toString();

          // Güvenli avatar sağlayıcısı (önce seçilen local, sonra network)
          ImageProvider? avatarImage;
          if (_selectedImage != null) {
            avatarImage = FileImage(_selectedImage!);
          } else if (photoUrl.isNotEmpty) {
            avatarImage = NetworkImage(photoUrl);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.indigo.shade100,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(name.isNotEmpty ? name[0] : "U", style: const TextStyle(fontSize: 40))
                            : null,
                      ),
                      if (_isEditing)
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        )
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Chip(
                  label: Text(widget.userRole.toUpperCase()),
                  backgroundColor: widget.userRole == 'baskan' ? Colors.red.shade100 : Colors.blue.shade100,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard("Üyelikler", "3", Icons.group),
                    _buildStatCard("Etkinlikler", "12", Icons.event_available),
                    _buildStatCard("Puan", "850", Icons.star),
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),

                _buildTextField("Bölüm", _deptController, Icons.school),
                const SizedBox(height: 15),
                _buildTextField("Hakkımda", _bioController, Icons.person, maxLines: 3),
                
                // ESKİ ÇIKIŞ BUTONU BURADAN SİLİNDİ
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(height: 5),
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      enabled: _isEditing, 
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
        filled: _isEditing,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}