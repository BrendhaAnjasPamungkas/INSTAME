import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/upload_story_usecase.dart';
import 'package:instagram/injection_container.dart';

class UploadStoryController extends GetxController {
  // Inject dependensi
  final UploadStoryUseCase uploadStoryUseCase = locator<UploadStoryUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();

  final ImagePicker _picker = ImagePicker();
  var isLoading = false.obs;

  // Fungsi yang dipanggil UI untuk memilih & upload
 Future<void> pickAndUploadStory() async {
    final currentAuthUser = firebaseAuth.currentUser;
    if (currentAuthUser == null) return;

    try {
      // 1. Tanya User: Foto atau Video?
      // (Kita pakai dialog sederhana untuk memilih)
      final isVideo = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Pilih Tipe Story"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text("Foto"),
                onTap: () => Get.back(result: false),
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text("Video"),
                onTap: () => Get.back(result: true),
              ),
            ],
          ),
        ),
      );

      if (isVideo == null) return; // Batal

      // 2. Pilih File (Image atau Video)
      final XFile? media;
      final StoryType type;

      if (isVideo) {
        media = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: Duration(seconds: 30), // Batasi durasi
        );
        type = StoryType.video;
      } else {
        media = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 50,
        );
        type = StoryType.image;
      }

      if (media == null) return;

      isLoading.value = true;
      // ... (tampilkan dialog loading)

      // 3. Baca Bytes
      final Uint8List fileBytes = await media.readAsBytes();

      // ... (Ambil data user)
      final userDataResult = await getUserDataUseCase(GetUserDataParams(currentAuthUser.uid));
      final UserEntity? currentUser = userDataResult.fold((l) => null, (r) => r);

      if (currentUser == null) throw Exception("Gagal ambil user");

      // 4. Upload dengan Tipe yang Benar
      final result = await uploadStoryUseCase(
        UploadStoryParams(
          imageBytes: fileBytes,
          type: type, // <-- Kirim tipe (image/video)
          authorId: currentUser.uid,
          authorUsername: currentUser.username,
          authorProfileUrl: currentUser.profileImageUrl,
        ),
      );
      
      // ... (Sisa kode penanganan sukses/gagal TETAP SAMA)
      Get.back(); // Tutup dialog loading
      isLoading.value = false;

      result.fold(
        (failure) => Get.snackbar("Error", failure.message),
        (success) {
          Get.snackbar("Sukses", "Story berhasil di-upload!");
          EventBus.fireFeed(FetchFeedEvent()); 
        }
      );

    } catch (e) {
      // ... (Error handling)
    }
  }
}