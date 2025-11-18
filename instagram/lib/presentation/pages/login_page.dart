import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/authcontroller.dart';
import 'package:instagram/presentation/pages/signup_page.dart';
// Import halaman sign up

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  // Buat controller untuk text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Agar bisa di-scroll jika keyboard muncul
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo (Kita pakai teks dulu)
                Image.asset(
                  "assets/logoinsta.png",
                  color: Colors.white,
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 48),

                // 2. Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[800], // UI Khas Instagram
                  ),
                ),
                SizedBox(height: 16),

                // 3. Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 24),

                // 4. Login Button (Menggunakan Obx)
                Obx(() {
                  // Widget ini akan re-build HANYA JIKA isLoading berubah
                  return controller.isLoading.value
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            // Panggil fungsi di controller
                            controller.signInUser(
                              _emailController.text,
                              _passwordController.text,
                            );
                          },
                          child: Text("Log In"),
                        );
                }),
                SizedBox(height: 24),

                // 5. Link ke Halaman Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        // Pindah ke SignUpPage
                        Get.to(() => SignUpPage());
                      },
                      child: Text(
                        "Sign Up.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
