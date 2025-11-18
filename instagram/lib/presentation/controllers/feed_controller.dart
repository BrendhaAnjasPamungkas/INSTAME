import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/usecase/delete_post_usecase.dart';
import 'package:instagram/domain/usecase/get_post_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/toggle_like_post_usecase.dart';
import 'package:instagram/injection_container.dart';

class FeedController extends GetxController {
  final GetPostsUseCase getPostsUseCase = locator<GetPostsUseCase>();
  // Di dalam FeedController
  String get currentUserId => firebaseAuth.currentUser?.uid ?? "";
  final ToggleLikePostUseCase toggleLikePostUseCase =
      locator<ToggleLikePostUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final DeletePostUseCase deletePostUseCase = locator<DeletePostUseCase>();

  // State untuk UI
  var isLoading = true.obs;
  var posts = <Post>[].obs; // Daftar postingan
  StreamSubscription? _postsSubscription;
  late StreamSubscription fetchFeedSubscription;
  late StreamSubscription _logoutSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchFeedSubscription = EventBus.feedStream.listen((event) {
      print("EventBus: Menerima sinyal FetchFeedEvent, memuat ulang feed...");
      fetchFeed(); // Panggil fetchFeed jika ada event
    });
    _logoutSubscription = EventBus.logoutStream.listen((event) {
      print("FEED: Logout terdeteksi. Membersihkan postingan...");
      posts.clear(); // Bersihkan list postingan
      isLoading.value = true; // Reset loading state
    });

    fetchFeed();
  }

  void fetchFeed() async {
    isLoading.value = true;

    // 1. Dapatkan ID user saat ini
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null) {
      return; // Tidak login
    }

    // 2. Dapatkan data user saat ini untuk list 'following'
    final userDataResult =
        await getUserDataUseCase(GetUserDataParams(currentUserId)).timeout(
          Duration(seconds: 10),
          onTimeout: () {
            // Ini akan berjalan jika 10 detik tidak ada jawaban
            return Left(
              ServerFailure(
                "Timeout: Gagal mengambil data user. Cek Firestore Rules.",
              ),
            );
          },
        );
    ;

    isLoading.value = false;

    userDataResult.fold(
      (failure) {
        isLoading.value = false;
        Get.snackbar("Error", "Gagal mengambil data user");
      },
      (user) {
        // 3. Ambil 'following' list (dan tambahkan ID kita sendiri)
        final List<String> followingIds = List.from(user.following);
        followingIds.add(user.uid); // Tampilkan postingan kita sendiri juga

        // 4. Berhenti 'listen' stream lama (jika ada)
        _postsSubscription?.cancel();

        // 5. 'Listen' ke stream baru dengan filter
        _postsSubscription = getPostsUseCase
            .execute(GetPostsParams(followingIds: followingIds))
            .listen(
              (eitherResult) {
                isLoading.value =
                    false; // Berhenti loading saat data pertama masuk

                eitherResult.fold(
                  (failure) {
                    Get.snackbar("Error Feed", failure.message);
                  },
                  (postList) {
                    posts.value = postList; // Update daftar postingan
                  },
                );
              },
              onError: (error) {
                isLoading.value = false;
                Get.snackbar("Error", error.toString());
              },
            );
      },
    );
  }

  void toggleLike(String postId) async {
    // <-- 1. Tambahkan 'async'
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar("Error", "Anda harus login untuk menyukai postingan.");
      return;
    }

    // 2. 'await' hasilnya
    final result = await toggleLikePostUseCase(
      ToggleLikePostParams(postId: postId, userId: userId),
    );

    // 3. Tangani hasilnya
    result.fold(
      (failure) {
        // Jika gagal, beri tahu user
        Get.snackbar("Gagal", "Gagal menyukai postingan: ${failure.message}");
      },
      (success) {
        // 4. JIKA SUKSES, tembakkan event untuk refresh feed
        EventBus.fireFeed(FetchFeedEvent());
      },
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      // Tampilkan loading dialog (opsional) atau indikator
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await deletePostUseCase(DeletePostParams(postId));

      // Tutup dialog loading
      Get.back();

      result.fold(
        (failure) {
          Get.snackbar("Error", "Gagal menghapus: ${failure.message}");
        },
        (success) {
          Get.snackbar("Sukses", "Postingan dihapus.");
          // Kita tidak perlu panggil fetchFeed() manual jika stream aktif,
          // TAPI kadang stream tidak mendeteksi delete di Firestore Web dengan cepat.
          // Jadi aman untuk memanggilnya atau menghapus item dari list lokal.

          // Cara cepat update UI: Hapus dari list lokal
          posts.removeWhere((p) => p.id == postId);

          // --- TAMBAHKAN INI ---
          // 2. Beri tahu ProfileController untuk refresh data (jumlah post & grid)
          EventBus.fireProfileUpdate(ProfileUpdateEvent());
        },
      );
    } catch (e) {
      Get.back(); // Tutup dialog jika error
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  void onClose() {
    _postsSubscription?.cancel(); // Hentikan stream saat controller ditutup
    fetchFeedSubscription.cancel();
    _logoutSubscription.cancel();
    super.onClose();
  }
}
