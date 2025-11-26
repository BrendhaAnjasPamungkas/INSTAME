import 'dart:async';
import 'dart:io';
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
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/post.dart';
// Pastikan path import usecases ini sesuai dengan struktur folder Anda
import 'package:instagram/injection_container.dart';

class FeedController extends GetxController {
  final GetPostsUseCase getPostsUseCase = locator<GetPostsUseCase>();
  final ToggleLikePostUseCase toggleLikePostUseCase =
      locator<ToggleLikePostUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final DeletePostUseCase deletePostUseCase = locator<DeletePostUseCase>();

  String get currentUserId => firebaseAuth.currentUser?.uid ?? "";

  var isLoading = true.obs;
  var posts = <Post>[].obs;

  StreamSubscription? _postsSubscription;
  late StreamSubscription _fetchFeedSubscription;
  late StreamSubscription _logoutSubscription;

  @override
  void onInit() {
    super.onInit();

    // 1. Listener Refresh Manual / Upload
    _fetchFeedSubscription = EventBus.feedStream.listen((event) {
      print("FEED: Refresh signal received");
      fetchFeed();
    });

    // --- 2. TAMBAHAN: Listener Update Profil (Follow/Unfollow) ---
    // Agar jika kita follow orang baru, feed langsung update
    EventBus.profileStream.listen((event) {
      print("FEED: Profil berubah (Follow/Unfollow). Refreshing feed...");
      fetchFeed();
    });
    // -------------------------------------------------------------

    _logoutSubscription = EventBus.logoutStream.listen((event) {
      posts.clear();
      isLoading.value = true;
      _postsSubscription?.cancel();
    });

    firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        print("AUTH: User siap. Fetching feed...");
        fetchFeed();
      } else {
        isLoading.value = false;
      }
    });
  }

  void fetchFeed() async {
    isLoading.value = true;

    // --- PENGAMAN WAKTU (TIMEOUT SAFETY) ---
    // Jika dalam 5 detik data tidak masuk, matikan loading paksa
    // Ini solusi ampuh untuk masalah "muter-muter" di akun baru
    Timer(Duration(seconds: 5), () {
      if (isLoading.value) {
        print("FEED: Timeout! Mematikan loading secara paksa.");
        isLoading.value = false;
      }
    });
    // ---------------------------------------

    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    final userDataResult = await getUserDataUseCase(GetUserDataParams(uid));

    userDataResult.fold(
      (failure) {
        print("FEED: Gagal user data -> ${failure.message}");
        isLoading.value = false;
      },
      (user) {
        final List<String> followingIds = List.from(user.following);
        followingIds.add(user.uid);

        _postsSubscription?.cancel();

        // Logika User Baru (Hanya follow diri sendiri)
        if (followingIds.length == 1) {
          print("FEED: User baru (belum follow orang).");
          // Tetap lanjut fetch, siapa tau user sudah post sesuatu
        }

        _postsSubscription = getPostsUseCase
            .execute(GetPostsParams(followingIds: followingIds))
            .listen(
              (eitherResult) {
                // MATIKAN LOADING SAAT DATA MASUK
                isLoading.value = false;

                eitherResult.fold(
                  (failure) {
                    print("FEED Error: ${failure.message}");
                  },
                  (postList) {
                    print("FEED Success: ${postList.length} postingan.");
                    posts.value = postList;
                  },
                );
              },
              onError: (error) {
                print("FEED Stream Error: $error");
                isLoading.value = false;
              },
            );
      },
    );
  }

  // --- FUNGSI TOGGLE LIKE (OPTIMISTIC UPDATE) ---
  void toggleLike(String postId) async {
    if (currentUserId.isEmpty) return;

    // 1. Update UI DULUAN (biar cepat merahnya)
    final index = posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final currentPost = posts[index];
      final isLiked = currentPost.likes.contains(currentUserId);

      // Buat list baru untuk update lokal
      final List<String> newLikes = List.from(currentPost.likes);
      if (isLiked) {
        newLikes.remove(currentUserId);
      } else {
        newLikes.add(currentUserId);
      }

      // Update observable list
      posts[index] = currentPost.copyWith(likes: newLikes);
    }

    // 2. Kirim ke Server
    final result = await toggleLikePostUseCase(
      ToggleLikePostParams(postId: postId, userId: currentUserId),
    );

    result.fold(
      (failure) {
        // Jika gagal, refresh feed untuk mengembalikan state asli
        fetchFeed();
        Get.snackbar("Gagal", failure.message);
      },
      (success) {
        // Sukses, tidak perlu apa-apa
      },
    );
  }

  // --- FUNGSI DELETE POST ---
  Future<void> deletePost(String postId) async {
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await deletePostUseCase(DeletePostParams(postId));

      Get.back(); // Tutup loading

      result.fold((failure) => Get.snackbar("Error", failure.message), (
        success,
      ) {
        Get.snackbar("Sukses", "Terhapus.");
        // Hapus manual dari list lokal agar instan
        posts.removeWhere((p) => p.id == postId);
        // Beri tahu profil juga
        EventBus.fireProfileUpdate(ProfileUpdateEvent());
      });
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar("Error", e.toString());
    }
  }

  // --- FUNGSI SHARE (WEB & MOBILE) ---
  void sharePost(String caption, String imageUrl, bool isVideo) async {
    final String shareText = '$caption\n\nLihat di: $imageUrl';

    // 1. LOGIKA WEB: Copy to Clipboard
    if (kIsWeb) {
      try {
        await Clipboard.setData(ClipboardData(text: shareText));
        Get.snackbar(
          "Link Disalin",
          "Tautan postingan telah disalin!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(16),
        );
      } catch (e) {
        Get.snackbar("Error", "Gagal menyalin link.");
      }
      return;
    }

    // 2. LOGIKA HP: Download & Share File
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 10),
              Text("Menyiapkan...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
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
      print("Share Error (Fallback to link): $e");
      // Fallback: Share Text Saja jika download gagal
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
