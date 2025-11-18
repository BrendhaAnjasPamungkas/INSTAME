import 'package:get/get.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/usecase/signin_usecase.dart';
import 'package:instagram/domain/usecase/signup_usecase.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/pages/home_page.dart';



class AuthController extends GetxController {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;

  AuthController():
  signUpUseCase = locator<SignUpUseCase>(),
  signInUseCase = locator<SignInUseCase>();

  // State untuk UI
  var isLoading = false.obs;

  Future<void> signUpUser(String username,String fullname,String email, String password) async {
    isLoading.value = true;
    
    final result = await signUpUseCase(SignUpParams(username: username,fullName: fullname,email: email, password: password));
    
    isLoading.value = false;

    result.fold(
      (failure) {
        // Tampilkan error
        Get.snackbar(
          "Error Sign Up",
          failure.toString(), // Anda bisa buat pesan error lebih baik
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (user) {
        // Sukses!
        Get.snackbar(
          "Success",
          "Akun berhasil dibuat: ${user.username}",
          snackPosition: SnackPosition.BOTTOM,
        );
        EventBus.fireFeed(FetchFeedEvent());
        // Pindah ke Halaman Home (misalnya)
        Get.offAll(() => HomePage());
      },
    );
  }
  Future<void> signInUser(String email, String password) async {
    isLoading.value = true;
    
    // Panggil SignInUseCase
    final result = await signInUseCase(SignInParams(email: email, password: password));
    
    isLoading.value = false;

    result.fold(
      (failure) {
        // Tampilkan error
        Get.snackbar(
          "Error Sign In",
          failure.message, // Ambil 'message' dari failure
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (user) {
        // Sukses!
        Get.snackbar(
          "Success",
          "Selamat datang kembali!, @${user.username}",
          snackPosition: SnackPosition.BOTTOM,
        );
        EventBus.fireFeed(FetchFeedEvent());
        // Pindah ke Halaman Home dan hapus halaman login dari stack
        Get.offAll(() => HomePage());
      },
    );
  }
}