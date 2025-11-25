import 'dart:io'; // 1. WAJIB IMPORT INI
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/presentation/pages/home_page.dart';
import 'package:instagram/presentation/pages/login_page.dart';
import 'package:instagram/presentation/pages/verification_page.dart';
import 'firebase_options.dart';
import 'package:instagram/injection_container.dart' as di;
import 'package:instagram/injection_container.dart';

// 2. KELAS KHUSUS UNTUK BYPASS SSL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. AKTIFKAN BYPASS SSL DI SINI
  // (Hapus 'if (!kIsWeb)' jika Anda hanya tes di HP agar lebih aman)
  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  di.init();

  final currentUser = locator<FirebaseAuth>().currentUser;
  Widget initialPage = currentUser != null ? HomePage() : LoginPage();
  if (currentUser != null) {
    // --- LOGIKA BARU: CEK EMAIL VERIFIED ---
    if (currentUser.emailVerified) {
      initialPage = HomePage();
    } else {
      // Jika sudah login tapi belum verifikasi, lempar ke sini
      initialPage = VerificationPage();
    }
    // --------------------------------------
  } else {
    initialPage = LoginPage();
  }

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
