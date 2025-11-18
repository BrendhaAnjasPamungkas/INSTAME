import 'dart:typed_data';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/update_user_data_usecase.dart';
import 'package:instagram/injection_container.dart';// Import locator

class EditProfileController extends GetxController {
  final UpdateUserDataUseCase updateUserDataUseCase =
      locator<UpdateUserDataUseCase>();
  final CloudinaryPublic cloudinary = locator<CloudinaryPublic>();

  final UserEntity currentUser;

  var isLoading = false.obs;
  final Rx<XFile?> selectedImage = Rx(null);
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
        imageQuality: 25, // Kompresi
      );
      if (image != null) {
        selectedImage.value = image;
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil gambar: $e");
    }
  }

  // Fungsi untuk menyimpan
Future<void> saveProfile() async {
    // 1. WAJIB: Tutup keyboard sebelum melakukan apa pun
    FocusManager.instance.primaryFocus?.unfocus();

    isLoading.value = true;
    
    String? newImageUrl;

    try {
      // ... (Logika upload gambar ke Cloudinary TETAP SAMA) ...
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

      // ... (Logika update Firestore TETAP SAMA) ...
     // ...
      // TAMBAHKAN 'final result =' DI DEPANNYA
      final result = await updateUserDataUseCase(
        UpdateUserDataParams(
          uid: currentUser.uid,
          newUsername: usernameController.text,
          newBio: bioController.text,
          newProfileImageUrl: newImageUrl,
        ),
      );
      // Buat object user baru
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
        (success) async { // Tambahkan async di sini
          print("DEBUG: Update sukses, menampilkan snackbar...");
          
          // 2. Tampilkan Snackbar
          Get.snackbar("Sukses", "Profil berhasil diperbarui.");
          
          // 3. TUNGGU sebentar agar snackbar muncul dan UI stabil
          // (Ini juga memberi waktu agar keyboard benar-benar tertutup)
          Future.delayed(Duration(milliseconds: 500), () {
          // GANTI Get.back() DENGAN INI:
          // Ini menggunakan Navigator Flutter asli yang lebih kuat
          Navigator.of(Get.context!).pop(updatedUser);
        });
        }
      );

    } catch (e) {
      print("DEBUG ERROR: $e");
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
