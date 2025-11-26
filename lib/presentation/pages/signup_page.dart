import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Hanya untuk Obx dan Get.snackbar
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/controllers/authcontroller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  // Siapkan controller untuk text
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // INI DIA CARANYA: Ambil controller dari GetIt, BUKAN Get.find()
  final AuthController controller = Get.put(
    AuthController(firebaseAuth: locator()),
    // tag opsional tapi bagus
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/logoinsta.png",
                color: Colors.white,
                height: 100,
                width: 200,
                fit: BoxFit.contain,
              ),
              W.gap(height: 18),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
              ),
              W.gap(height: 10),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
              ),
              W.gap(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
              ),
              W.gap(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                obscureText: true,
              ),
              W.gap(height: 20),

              // Gunakan Obx untuk listen ke state 'isLoading'
              Obx(() {
                return controller.isLoading.value
                    ? CircularProgressIndicator()
                    : W.button(
                        width: Get.width,
                        child: W.text(data: "Sign Up"),
                        onPressed: () {
                          controller.signUpUser(
                            _emailController.text,
                            _passwordController.text,
                            _fullNameController.text,
                            _usernameController.text,
                          );
                        },
                        backgroundColor: Colors.blueAccent,
                      );
              }),
              W.gap(height: 24), // Beri jarak

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Sudah punya akun? "),
                  GestureDetector(
                    onTap: () {
                      // Panggil Get.back() untuk kembali ke halaman
                      // sebelumnya (yaitu LoginPage)
                      Get.back();
                    },
                    child: Text(
                      "Log In.",
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
    );
  }
}
