import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Hanya untuk Obx dan Get.snackbar
import 'package:instagram/presentation/controllers/authcontroller.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  // Siapkan controller untuk text
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // INI DIA CARANYA: Ambil controller dari GetIt, BUKAN Get.find()
  final AuthController controller = Get.put(
    AuthController(),
    // tag opsional tapi bagus
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Instagram Clone", style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: "Username"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: "Nama Lengkap"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              SizedBox(height: 20),

              // Gunakan Obx untuk listen ke state 'isLoading'
              Obx(() {
                return controller.isLoading.value
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          // Panggil fungsi di controller
                          controller.signUpUser(
                            _usernameController.text,
                            _fullNameController.text,
                            _emailController.text,
                            _passwordController.text,
                          );
                        },
                        child: Text("Sign Up"),
                      );
              }),
              SizedBox(height: 24), // Beri jarak

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
