import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/controllers/authcontroller.dart';
import 'package:instagram/presentation/pages/forget_password_page.dart';
import 'package:instagram/presentation/pages/signup_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
// Import halaman sign up

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  // Buat controller untuk text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController controller = Get.put(
    AuthController(firebaseAuth: locator()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            height: Get.height,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Spacer(),
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
                  Obx(() {
                    return controller.isLoading.value
                        ? Center(child: CircularProgressIndicator())
                        : W.button(
                            width: Get.width,
                            child: W.text(data: "Log In"),
                            onPressed: () {
                              controller.signInUser(
                                _emailController.text,
                                _passwordController.text,
                              );
                            },
                            backgroundColor: Colors.blueAccent,
                          );
                  }),
                  W.gap(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.to(() => ForgotPasswordPage()),
                      child: W.text(
                        data: "Lupa password?",
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      W.button(
                        child: W.text(
                          data: "Buat Akun Baru",
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () => Get.to(SignUpPage()),
                        backgroundColor: Colors.transparent,
                        borderColor: Colors.blue,
                        width: Get.width,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
