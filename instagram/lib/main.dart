import 'dart:io'; // Tetap di-import (aman)
import 'package:flutter/foundation.dart'; // PENTING: Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/presentation/pages/home_page.dart';
import 'package:instagram/presentation/pages/login_page.dart';
import 'firebase_options.dart';
import 'package:instagram/injection_container.dart' as di;
import 'package:instagram/injection_container.dart';

// Kelas Bypass SSL (Hanya dipakai di HP)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- PERBAIKAN: Cek Platform ---
  // Jika BUKAN Web (!kIsWeb), baru aktifkan bypass SSL
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
  // -------------------------------
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  di.init();

  final currentUser = locator<FirebaseAuth>().currentUser;
  final Widget initialPage = currentUser != null ? HomePage() : LoginPage();

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({Key? key, required this.initialPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Instagram Clone',
      theme: ThemeData.dark(),
      home: initialPage,
      debugShowCheckedModeBanner: false,
    );
  }
}