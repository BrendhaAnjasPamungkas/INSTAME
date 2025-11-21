import 'dart:typed_data'; // Untuk base64Encode (jika masih pakai untuk preview lama)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/post.dart'; // Import PostType
import 'package:instagram/domain/usecase/create_post_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/injection_container.dart';

class UploadController extends GetxController {
  final CreatePostUseCase createPostUseCase = locator<CreatePostUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();

  final ImagePicker _picker = ImagePicker();

  // State
  var isLoading = false.obs;
  final Rx<XFile?> selectedImage = Rx(null);

  // --- VARIABEL BARU: Menyimpan Tipe (Foto/Video) ---
  var selectedType = PostType.image;
  // --------------------------------------------------

  Future<void> pickImage() async {
    try {
      // 1. Dialog Pilihan
      final isVideo = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Buat Postingan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: Icon(Icons.image), title: Text("Foto"), onTap: () => Get.back(result: false)),
              ListTile(leading: Icon(Icons.videocam), title: Text("Video"), onTap: () => Get.back(result: true)),
            ],
          ),
        )
      );

      if (isVideo == null) return;

      final XFile? media;
      
      // 2. LOGIKA PEMILIHAN (CEK INI BAIK-BAIK)
      if (isVideo) {
        media = await _picker.pickVideo(source: ImageSource.gallery);
        
        // --- WAJIB ADA: UBAH TIPE JADI VIDEO ---
        selectedType = PostType.video; 
        // ---------------------------------------
        
      } else {
        media = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
        
        // --- WAJIB ADA: UBAH TIPE JADI IMAGE ---
        selectedType = PostType.image; 
        // ---------------------------------------
      }

      if (media != null) {
        selectedImage.value = media; 
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal: $e");
    }
  }

  Future<void> uploadPost(String caption) async {
    if (selectedImage.value == null) {
      Get.snackbar("Error", "Silakan pilih file terlebih dahulu.");
      return;
    }

    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "Login dulu.");
      return;
    }

    try {
      isLoading.value = true;

      // 1. Ambil data user
      final userDataResult = await getUserDataUseCase(
        GetUserDataParams(currentUser.uid),
      );
      final user = userDataResult.fold((l) => null, (r) => r);

      if (user == null) throw Exception("Gagal ambil user");

      // 2. Baca File
      final Uint8List fileBytes = await selectedImage.value!.readAsBytes();

      // 3. Panggil UseCase dengan Tipe yang BENAR
      final result = await createPostUseCase(
        CreatePostParams(
          imageBytes: fileBytes,
          caption: caption,
          authorId: currentUser.uid,
          authorUsername: user.username,
          authorProfileUrl: user.profileImageUrl,
          type: selectedType, // <-- KIRIM TIPE INI (PENTING!)
        ),
      );

      isLoading.value = false;

      result.fold(
        (failure) {
          Get.snackbar("Error", failure.message);
        },
        (success) {
          Get.snackbar("Sukses", "Postingan berhasil di-upload!");
          _clear();
          EventBus.fireFeed(FetchFeedEvent());
          EventBus.fireProfileUpdate(ProfileUpdateEvent());

          // Pindah ke Feed (Tab 0)
          // (Pastikan NavigationController terdaftar atau gunakan EventBus)
          EventBus.fire(TabNavigationEvent(0));
        },
      );
    } catch (e) {
      isLoading.value = false;
      print("UPLOAD ERROR: $e");
      Get.snackbar("Error Kritis", "Gagal: $e");
    }
  }

  void _clear() {
    selectedImage.value = null;
    selectedType = PostType.image; // Reset ke default
  }
}
