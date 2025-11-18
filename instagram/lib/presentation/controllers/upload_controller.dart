import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/usecase/create_post_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/injection_container.dart';

class UploadController extends GetxController {
  final CreatePostUseCase createPostUseCase;
  final FirebaseAuth firebaseAuth;
  final GetUserDataUseCase getUserDataUseCase;

  UploadController()
    : createPostUseCase = locator<CreatePostUseCase>(),
      firebaseAuth = locator<FirebaseAuth>(),
      getUserDataUseCase = locator<GetUserDataUseCase>();

  final ImagePicker _picker = ImagePicker();

  // State untuk UI
  var isLoading = false.obs;
  var selectedType = PostType.image;
  final Rx<XFile?> selectedImage = Rx(null); // File gambar yang dipilih

  // Fungsi untuk memilih gambar dari galeri
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
      if (isVideo) {
        media = await _picker.pickVideo(source: ImageSource.gallery);
        selectedType = PostType.video; // Simpan tipe
      } else {
        media = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
        selectedType = PostType.image; // Simpan tipe
      }

      if (media != null) {
        selectedImage.value = media; // (Variabel ini bisa simpan video juga krn tipe XFile)
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil gambar: ${e.toString()}");
    }
  }

  // Fungsi untuk meng-upload postingan
  Future<void> uploadPost(String caption) async {
    if (selectedImage.value == null) {
      Get.snackbar("Error", "Silakan pilih gambar terlebih dahulu.");
      return;
    }

    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "Anda harus login untuk membuat postingan.");
      return;
    }

    try {
      isLoading.value = true;

      // 1. Baca data gambar sebagai bytes (Uint8List)

      // 2. KONVERSI KE BASE64 (INI KUNCINYA)
      final Uint8List imageBytes = await selectedImage.value!.readAsBytes();
      final userDataResult = await getUserDataUseCase(
        GetUserDataParams(currentUser.uid),
      );
      final user = userDataResult.fold(
        (failure) => null,
        (userEntity) => userEntity,
      ); // Jika sukses (Right), 'user' akan jadi UserEntity

      if (user == null) {
        throw ServerException("Gagal mengambil data user untuk posting.");
      }

      // 4. Panggil UseCase dengan data Base64
      final result = await createPostUseCase(
        CreatePostParams(
          // Kirim 'String' (data URI), BUKAN 'bytes'
          imageBytes: imageBytes,
          caption: caption,
          authorId: currentUser.uid,
          authorUsername: user.username, // <-- KIRIM USERNAME
          authorProfileUrl: user.profileImageUrl,
          type: selectedType
        ),
      );

      isLoading.value = false;

      result.fold(
        (failure) {
          Get.snackbar("Error", failure.message);
          print("--- UPLOAD GAGAL (Failure) ---");
          print(failure.message);
          isLoading.value = false; // --- LOADING BERHENTI ---
          Get.snackbar("Error", failure.message);
        },
        (success) {
          EventBus.fireFeed(FetchFeedEvent());
          EventBus.fireProfileUpdate(ProfileUpdateEvent());

          Get.snackbar("Sukses", "Postingan berhasil di-upload!");

          // --- INI PERBAIKANNYA ---
          // Kirim pesan ke EventBus, tanpa tahu siapa yang dengar
          _clear();
          EventBus.fire(TabNavigationEvent(0));
          // ---
        },
      );
    } catch (e) {
      isLoading.value = false;
      print("--- ERROR KRITIS SAAT UPLOAD ---");
      print(e.toString());
      // Periksa error 'RESOURCE_EXHAUSTED', itu artinya file terlalu besar (di atas 1MB)
      Get.snackbar("Error Kritis", "Gagal memproses gambar: ${e.toString()}");
    }
  }

  // Bersihkan state setelah upload sukses
  void _clear() {
    selectedImage.value = null;
  }
}
