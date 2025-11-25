import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/presentation/controllers/edit_profile_controller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class EditProfilePage extends StatelessWidget {
  final UserEntity currentUser;

  const EditProfilePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EditProfileController controller = Get.put(
      EditProfileController(currentUser: currentUser),
    );

    // 1. Bungkus semuanya dengan Obx agar bereaksi terhadap 'isLoading'
    return Obx(() {
      final bool isLoading = controller.isLoading.value;

      // 2. PopScope Mencegah tombol 'Back' fisik/gesture di HP
      return PopScope(
        canPop: !isLoading, // Kalau loading, GABISA back
        child: Scaffold(
          appBar: AppBar(
            title: W.text(data: "Edit Profil"),
            // 3. Tombol Back Manual (di Kiri Atas) -> Matikan saat loading
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              // Jika loading, tombol mati (null). Jika tidak, back.
              onPressed: isLoading ? null : () => Get.back(),
            ),
            actions: [
              // Tombol Simpan (Sudah benar sebelumnya)
              isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: Icon(Icons.check, color: Colors.blue),
                      onPressed: () => controller.saveProfile(),
                    ),
            ],
          ),
          
          // 4. AbsorbPointer: Memblokir semua sentuhan di body saat loading
          body: AbsorbPointer(
            absorbing: isLoading, // Jika true, layar tidak bisa disentuh
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Bagian Foto Profil
                  // --- BAGIAN FOTO PROFIL ---
                  GestureDetector(
                    onTap: () => controller.pickImage(),
                    child: Obx(() {
                      ImageProvider? backgroundImage;
                      Widget? childWidget;

                      // --- LOGIKA BARU (URUTAN PENTING) ---

                      // 1. PRIORITAS UTAMA: Jika User Menekan "Hapus"
                      if (controller.isPhotoRemoved.value) {
                        backgroundImage = null; // Tidak ada gambar
                        childWidget = Icon(Icons.person, size: 60, color: Colors.grey[600]);
                      }
                      
                      // 2. PRIORITAS KEDUA: Jika User Memilih Foto Baru (Lokal)
                      else if (controller.selectedImage.value != null) {
                         if (kIsWeb) {
                           backgroundImage = NetworkImage(controller.selectedImage.value!.path);
                        } else {
                           backgroundImage = FileImage(File(controller.selectedImage.value!.path));
                        }
                        childWidget = null; // Gambar akan menutupi, tidak perlu icon
                      }
                      
                      // 3. PRIORITAS KETIGA: Foto Lama (Database)
                      else if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
                        backgroundImage = CachedNetworkImageProvider(currentUser.profileImageUrl!);
                        childWidget = null;
                      }
                      
                      // 4. DEFAULT: Tidak ada foto sama sekali
                      else {
                        backgroundImage = null;
                        childWidget = Icon(Icons.person, size: 60, color: Colors.grey[600]);
                      }
                      // ------------------------------------

                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: backgroundImage,
                        child: childWidget,
                      );
                    }),
                  ),
                  W.gap(height: 8),
                  Obx(() {
                     // Cek apakah ada foto saat ini (Entah foto lama, atau foto baru yg dipilih)
                     // Dan pastikan belum ditandai hapus
                     bool hasPhoto = (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) || 
                                     (controller.selectedImage.value != null);
                     
                     if (controller.isPhotoRemoved.value) hasPhoto = false;

                     return Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         // Tombol Ganti
                         GestureDetector(
                            onTap: () => controller.pickImage(),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: W.text(data: "Ganti Foto", color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                         ),
                         
                         // Tombol Hapus (Hanya muncul jika ada foto)
                         if (hasPhoto) ...[
                           W.gap(width: 16),
                           GestureDetector(
                              onTap: () => controller.removePhoto(),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red)
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    SizedBox(width: 4),
                                    W.text(data: "Hapus", color: Colors.red, fontWeight: FontWeight.bold),
                                  ],
                                ),
                              ),
                           ),
                         ]
                       ],
                     );
                  }),
                  // Text ini juga tidak akan bisa diklik karena AbsorbPointer
                 
                  
                  W.gap(height: 24),
                  
                  // Form Input (Disabled visual effect optional, tapi sudah unclickable)
                  W.textField(
                    controller: controller.usernameController,
                    label: W.text(data: "Username"),
                    fontColor: isLoading ? Colors.grey : Colors.white,
                    fillColor: Colors.grey[800],
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  W.gap(height: 16),
                  W.textField(
                    controller: controller.bioController,
                    label: W.text(data: "Bio"),
                    maxLines: 4,
                    fontColor: isLoading ? Colors.grey : Colors.white,
                    fillColor: Colors.grey[800],
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}