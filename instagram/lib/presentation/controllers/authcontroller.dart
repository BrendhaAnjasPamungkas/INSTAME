import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/usecase/send_email_verification_usecase.dart';
import 'package:instagram/domain/usecase/send_password_usecase.dart';
import 'package:instagram/domain/usecase/signin_usecase.dart';
import 'package:instagram/domain/usecase/signup_usecase.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/pages/home_page.dart';
import 'package:instagram/presentation/pages/verification_page.dart';



class AuthController extends GetxController {
  
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final FirebaseAuth firebaseAuth; // Variabel class
  

  AuthController({required this.firebaseAuth}):
  signUpUseCase = locator<SignUpUseCase>(),
  signInUseCase = locator<SignInUseCase>();
  
  final SendPasswordResetUseCase sendPasswordResetUseCase = locator<SendPasswordResetUseCase>();
  final SendEmailVerificationUseCase sendEmailVerificationUseCase = locator<SendEmailVerificationUseCase>();
  

  // State untuk UI
  var isLoading = false.obs;


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
  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar("Error", "Masukkan email Anda.");
      return;
    }

    isLoading.value = true;
    
    final result = await sendPasswordResetUseCase(email);
    
    isLoading.value = false;

    result.fold(
      (failure) => Get.snackbar("Gagal", failure.message),
      (success) {
        Get.snackbar("Sukses", "Link reset password telah dikirim ke email Anda.");
        Get.back(); // Kembali ke Login Page
      }
    );
  }

  // 2. MODIFIKASI SIGN UP (Kirim Verifikasi)
  Future<void> signUpUser(String username, String fullName, String email, String password) async {
    isLoading.value = true;

    final result = await signUpUseCase(
      SignUpParams(username: username, fullName: fullName, email: email, password: password),
    );

    result.fold(
      (failure) {
        isLoading.value = false;
        Get.snackbar("Error Sign Up", failure.message);
      },
      (user) async {
        // --- TAMBAHAN: KIRIM EMAIL VERIFIKASI ---
        await sendEmailVerificationUseCase(NoParams());
        // ----------------------------------------

        isLoading.value = false;
        
        Get.snackbar("Sukses", "Akun dibuat! Silakan cek email untuk verifikasi.");
        
        // Opsional: Paksa logout agar user login ulang setelah verifikasi
        // await logOutUseCase(NoParams()); 
        // Get.offAll(() => LoginPage());

        // Atau biarkan masuk tapi batasi fitur (biasanya langsung masuk Home)
        EventBus.fireFeed(FetchFeedEvent());
        Get.offAll(() => VerificationPage());
      },
    );
  }
  Future<void> checkEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      // Wajib reload agar status emailVerified ter-update dari server
      await user.reload(); 
      
      // Ambil data user terbaru setelah reload
      final updatedUser = firebaseAuth.currentUser; 

      if (updatedUser != null && updatedUser.emailVerified) {
        Get.snackbar("Sukses", "Email terverifikasi! Selamat datang.");
        // Sinkronisasi data jika perlu, lalu masuk Home
        EventBus.fireFeed(FetchFeedEvent());
        Get.offAll(() => HomePage());
      } else {
        Get.snackbar("Belum Verifikasi", "Silakan klik link di email Anda terlebih dahulu.",
          backgroundColor: Colors.orange, colorText: Colors.white);
      }
    }
  }
  
  // Fungsi kirim ulang (jika email hilang)
  Future<void> resendVerificationEmail() async {
    final user = firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      Get.snackbar("Terkirim", "Link verifikasi baru telah dikirim.");
    }
  }
}