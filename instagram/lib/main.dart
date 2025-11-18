import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORT INI
import 'package:instagram/presentation/pages/home_page.dart';
import 'package:instagram/presentation/pages/login_page.dart';
import 'firebase_options.dart';
import 'package:instagram/injection_container.dart' as di;
import 'package:instagram/injection_container.dart'; // Import locator

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  di.init();
  final currentUser = locator<FirebaseAuth>().currentUser;
  // ---

  // 4. Tentukan halaman awal
  final Widget initialPage = currentUser != null ? HomePage() : LoginPage();

  // 5. Jalankan aplikasi
  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({Key? key, required this.initialPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram Clone',
      theme: ThemeData.dark(),
      home: initialPage,
    );
  }
}
