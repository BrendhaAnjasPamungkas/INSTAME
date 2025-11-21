import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/domain/usecase/delete_post_usecase.dart';
import 'package:instagram/domain/usecase/get_post_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/toggle_like_post_usecase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/post.dart';
// --- PERBAIKAN IMPORT (usecases pakai 's') ---
// --------------------------------------------
import 'package:instagram/injection_container.dart';

class FeedController extends GetxController {
  // 1. Dependensi (Locator)
  // Menggunakan constructor 'call' locator secara langsung
  final GetPostsUseCase getPostsUseCase = locator<GetPostsUseCase>();
  final ToggleLikePostUseCase toggleLikePostUseCase = locator<ToggleLikePostUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final DeletePostUseCase deletePostUseCase = locator<DeletePostUseCase>();

  // Getter Current User ID
  String get currentUserId => firebaseAuth.currentUser?.uid ?? "";

  // State UI
  var isLoading = true.obs;
  var posts = <Post>[].obs;
  
  // Subscriptions
  StreamSubscription? _postsSubscription;
  late StreamSubscription _fetchFeedSubscription;
  late StreamSubscription _logoutSubscription;

  @override
  void onInit() {
    super.onInit();

    // 1. Listener EventBus (Refresh Feed)
    _fetchFeedSubscription = EventBus.feedStream.listen((event) {
      print("FEED: Sinyal refresh diterima. Memuat ulang...");
      fetchFeed();
    });

    // 2. Listener Logout (Bersihkan Data)
    _logoutSubscription = EventBus.logoutStream.listen((event) {
      print("FEED: Logout. Membersihkan data...");
      posts.clear();
      isLoading.value = true;
      _postsSubscription?.cancel();
    });

    // 3. Listener Auth (Auto-Fetch saat Login)
    // onData akan terpanggil otomatis saat user login/logout atau saat app baru buka
    firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        print("AUTH: User ${user.uid} siap. Mengambil feed...");
        fetchFeed();
      }
    });
  }

  void fetchFeed() async {
    isLoading.value = true;
    
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      print("FEED: User belum login. Stop.");
      isLoading.value = false;
      return; 
    }

    // 1. Ambil Data User (Following)
    final userDataResult = await getUserDataUseCase(GetUserDataParams(uid));
    
    userDataResult.fold(
      (failure) {
        print("FEED: Gagal ambil user: ${failure.message}");
        isLoading.value = false;
        // Opsional: Tampilkan error jika bukan karena masalah koneksi sementara
      },
      (user) {
        // 2. Susun List Following + Diri Sendiri
        final List<String> followingIds = List.from(user.following);
        followingIds.add(user.uid); 

        print("FEED: Mengambil post dari ${followingIds.length} orang...");

        // 3. Cancel Stream Lama & Buat Baru
        _postsSubscription?.cancel();

        _postsSubscription = getPostsUseCase.execute(GetPostsParams(followingIds: followingIds))
          .listen((eitherResult) {
            
            // PENTING: Matikan loading begitu stream merespon (sukses/gagal)
            isLoading.value = false; 
            
            eitherResult.fold(
              (failure) {
                print("FEED: Gagal ambil post: ${failure.message}");
                // Jika index belum dibuat, errornya akan muncul di sini (atau di console log)
              },
              (postList) {
                print("FEED: Sukses! ${postList.length} postingan ditemukan.");
                posts.value = postList; 
              },
            );
          }, onError: (error) {
            print("FEED: Stream Error: $error");
            isLoading.value = false;
          });
      }
    );
  }

  void toggleLike(String postId) async {
    if (currentUserId.isEmpty) {
      Get.snackbar("Error", "Login dulu bos.");
      return;
    }

    // Optimistic Update (Opsional): Bisa update UI dulu di sini biar cepat

    final result = await toggleLikePostUseCase(
      ToggleLikePostParams(postId: postId, userId: currentUserId),
    );

    result.fold(
      (failure) => Get.snackbar("Gagal", failure.message),
      (success) {
        // Trigger refresh agar UI sync (terutama jika pindah device)
        // EventBus.fireFeed(FetchFeedEvent()); 
        // *Catatan: Jika pakai Stream, biasanya tidak perlu fire event lagi 
        // karena stream akan otomatis update. Tapi jika macet, nyalakan baris ini.
      },
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);

      final result = await deletePostUseCase(DeletePostParams(postId));

      Get.back(); // Tutup loading

      result.fold(
        (failure) => Get.snackbar("Error", failure.message),
        (success) {
          Get.snackbar("Sukses", "Terhapus.");
          // Hapus manual dari list lokal agar instan
          posts.removeWhere((p) => p.id == postId);
          // Beri tahu profil juga
          EventBus.fireProfileUpdate(ProfileUpdateEvent());
        },
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar("Error", e.toString());
    }
  }

  // --- FUNGSI SHARE (KOMPATIBEL WEB & HP) ---
  void sharePost(String caption, String imageUrl, bool isVideo) async {
    final String shareText = '$caption\n\nLihat di: $imageUrl';

    // 1. LOGIKA WEB: Copy to Clipboard
   if (kIsWeb) {
      print("WEB SHARE: Mencoba menyalin ke clipboard..."); // <-- CEK LOG INI
      
      try {
        await Clipboard.setData(ClipboardData(text: '$caption\n\nLihat di: $imageUrl'));
        print("WEB SHARE: Berhasil disalin!"); 
        
        // Tampilkan Snackbar
        Get.snackbar(
          "Berhasil", 
          "Link sudah disalin ke clipboard! Silakan Paste.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(16),
        );
      } catch (e) {
        print("WEB SHARE ERROR: $e");
      }
      return; 
    }
    // 2. LOGIKA HP: Download & Share File
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text("Menyiapkan...", style: TextStyle(color: Colors.white))
          ]),
        ),
      ), barrierDismissible: false
    );

    try {
      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri);
      
      if (response.statusCode != 200) throw Exception("Gagal download");

      final tempDir = await getTemporaryDirectory();
      final extension = isVideo ? 'mp4' : 'jpg';
      final filePath = '${tempDir.path}/share_temp.$extension';
      
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      Get.back(); // Tutup Loading

      // Share menggunakan XFile
      await Share.shareXFiles([XFile(filePath)], text: caption);

    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      // Fallback: Share Text Saja
      Share.share(shareText);
    }
  }

  @override
  void onClose() {
    _postsSubscription?.cancel();
    _fetchFeedSubscription.cancel();
    _logoutSubscription.cancel();
    super.onClose();
  }
}