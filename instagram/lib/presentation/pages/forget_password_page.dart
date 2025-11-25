import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/controllers/authcontroller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart'; // W widget

class ForgotPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  
  // Kita gunakan AuthController yang sudah ada (biasanya di-put di LoginPage)
  // Atau find jika sudah ada di stack
  final AuthController controller = Get.put(AuthController(firebaseAuth: locator()));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: W.text(data: "Lupa Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            W.text(
              data: "Masukkan email Anda, kami akan mengirimkan link untuk mereset password.",
              textAlign: TextAlign.center,
              color: Colors.grey
            ),
            W.gap(height: 20),
            
            // Input Email
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: TextField(
                controller: emailController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            W.gap(height: 20),

            // Tombol Kirim
            Obx(() => controller.isLoading.value
                ? CircularProgressIndicator()
                : W.button(
                    width: double.infinity,
                    child: W.text(data: "kirim Link Reset"),
                    onPressed: () {
                      controller.resetPassword(emailController.text.trim());
                    },
                  )
            ),
            
          ],
        ),
      ),
    );
  }
}