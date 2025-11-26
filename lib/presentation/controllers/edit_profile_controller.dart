import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart'; // Perlu ini untuk Navigator & FocusManager
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/update_user_data_usecase.dart';
import 'package:instagram/injection_container.dart';

class EditProfileController extends GetxController {
  final UpdateUserDataUseCase updateUserDataUseCase = locator<UpdateUserDataUseCase>();
  final CloudinaryPublic cloudinary = locator<CloudinaryPublic>();
  
  final UserEntity currentUser;

  var isLoading = false.obs;
  
  // Gambar lokal yang baru dipilih
  final Rx<XFile?> selectedImage = Rx(null);
  
  // Status Hapus Foto
  var isPhotoRemoved = false.obs; 

  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController usernameController;
  late TextEditingController bioController;

  EditProfileController({required this.currentUser}) {
    usernameController = TextEditingController(text: currentUser.username);
    bioController = TextEditingController(text: currentUser.bio ?? "");
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
      );
      if (image != null) {
        selectedImage.value = image;
        isPhotoRemoved.value = false; // Reset status hapus
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil gambar: $e");
    }
  }

  void removePhoto() {
    selectedImage.value = null;
    isPhotoRemoved.value = true;
  }

  Future<void> saveProfile() async {
    // 1. Tutup keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    
    isLoading.value = true;
    
    String? newImageUrl;

    try {
      // 2. Upload Foto (Jika ada gambar baru)
      if (selectedImage.value != null) {
        final Uint8List imageBytes = await selectedImage.value!.readAsBytes();
        final byteData = imageBytes.buffer.asByteData();

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            byteData,
            identifier: 'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}',
            folder: "profiles", 
          ),
        );
        newImageUrl = response.secureUrl;
      } 
      // 3. Cek Hapus Foto
      else if (isPhotoRemoved.value) {
        newImageUrl = ""; 
      }

      // 4. Update Firestore
      final result = await updateUserDataUseCase(
        UpdateUserDataParams(
          uid: currentUser.uid,
          newUsername: usernameController.text,
          newBio: bioController.text,
          newProfileImageUrl: newImageUrl,
        ),
      );

      // 5. Buat Object User Baru
      final updatedUser = currentUser.copyWith(
        username: usernameController.text,
        bio: bioController.text,
        profileImageUrl: newImageUrl ?? currentUser.profileImageUrl, 
      );

      isLoading.value = false;

      result.fold(
        (failure) {
          Get.snackbar("Error", failure.message);
        },
        (success) async { 
          // 6. Beri tahu aplikasi
          EventBus.fireProfileUpdate(ProfileUpdateEvent());
          
          Get.snackbar("Sukses", "Profil berhasil diperbarui.");
          
          // 7. Jeda sebentar
          await Future.delayed(Duration(milliseconds: 500));
          
          // --- PENGGANTIAN KE NAVIGATOR POP ---
          // Kita gunakan context global dari GetX
          if (Get.context != null) {
            Navigator.of(Get.context!).pop(updatedUser);
          }
          // ------------------------------------
        }
      );

    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Gagal update profil: $e");
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    bioController.dispose();
    super.onClose();
  }
}