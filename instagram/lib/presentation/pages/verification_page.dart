import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/authcontroller.dart';
import 'package:instagram/presentation/pages/login_page.dart'; // Untuk tombol logout/batal
import 'package:instagram/presentation/widgets/main_widget.dart';

class VerificationPage extends StatelessWidget {
  // Kita cari AuthController yang sudah ada (karena kita habis register/login)
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 100, color: Colors.white),
            W.gap(height: 20),
            
            W.text(
              data: "Verifikasi Email",
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            W.gap(height: 10),
            
            W.text(
              data: "Kami telah mengirimkan tautan verifikasi ke email Anda. Silakan klik tautan tersebut lalu tekan tombol di bawah.",
              textAlign: TextAlign.center,
              color: Colors.grey,
            ),
            
            W.gap(height: 40),

            // Tombol Cek Status
            W.button(
              width: double.infinity,
              child: W.text(data: "Email sudah diverifikasi"),
              onPressed: () {
                controller.checkEmailVerification();
              },
            ),
            
            W.gap(height: 16),

            // Tombol Kirim Ulang
            TextButton(
              onPressed: () {
                controller.resendVerificationEmail();
              },
              child: W.text(data: "Kirim ulang email", color: Colors.blue),
            ),

            W.gap(height: 30),
            
            // Tombol Keluar (Jika salah email)
            TextButton(
              onPressed: () {
                // Logout paksa dan kembali ke login
                controller.firebaseAuth.signOut();
                Get.offAll(() => LoginPage());
              },
              child: W.text(data: "Batal / Ganti Akun", color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}