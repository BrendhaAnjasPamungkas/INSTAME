import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/comment.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/add_comment_usecase.dart';
import 'package:instagram/domain/usecase/delete_comment_usecase.dart';
import 'package:instagram/domain/usecase/get_comment_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/toggle_like_comment_usecase.dart';
import 'package:instagram/injection_container.dart';

class CommentsController extends GetxController {
  // Ambil UseCase dari locator
  final GetCommentsUseCase getCommentsUseCase = locator<GetCommentsUseCase>();
  final AddCommentUseCase addCommentUseCase = locator<AddCommentUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final DeleteCommentUseCase deleteCommentUseCase = locator<DeleteCommentUseCase>();
  final ToggleLikeCommentUseCase toggleLikeCommentUseCase =
      locator<ToggleLikeCommentUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();

  // ID Postingan yang sedang dilihat
  final String postId;

  CommentsController({required this.postId});

  // State
  var isLoading = true.obs;
  var isPostingComment = false.obs;
  var comments = <CommentEntity>[].obs; // Daftar komentar
  final Rx<CommentEntity?> replyingTo = Rx(null);
  
  // FocusNode untuk mengatur keyboard
  final FocusNode focusNode = FocusNode();

  // Controller untuk input teks
  final TextEditingController textController = TextEditingController();

  StreamSubscription? _commentsSubscription;
  var currentUserProfilePic = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchComments();
    _loadCurrentUserProfile();
  }
void startReplying(CommentEntity comment) {
    replyingTo.value = comment;
    
    // Otomatis tambahkan "@username " ke text field
    textController.text = "@${comment.authorUsername} ";
    
    // Pindahkan kursor ke paling belakang teks
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length)
    );

    // Buka keyboard
    focusNode.requestFocus(); 
  }

  void cancelReply() {
    replyingTo.value = null;
    textController.clear(); // Bersihkan teks juga jika batal
    focusNode.unfocus();
  }
  void _loadCurrentUserProfile() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid != null) {
      final result = await getUserDataUseCase(GetUserDataParams(uid));
      result.fold(
        (l) => null,
        (user) => currentUserProfilePic.value = user.profileImageUrl ?? "",
      );
    }
  }

  // 1. Mengambil komentar
  void fetchComments() {
    isLoading.value = true;
    _commentsSubscription?.cancel(); // Batalkan stream lama (jika ada)

    _commentsSubscription = getCommentsUseCase
        .execute(GetCommentsParams(postId: postId))
        .listen(
          (eitherResult) {
            isLoading.value = false; // Berhenti loading saat data pertama masuk

            eitherResult.fold(
              (failure) {
                Get.snackbar("Error", failure.message);
              },
              (commentList) {
                comments.value = commentList; // Update daftar komentar
              },
            );
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar("Error", error.toString());
          },
        );
  }

  // 2. Menambahkan komentar
  Future<void> postComment() async {
    final content = textController.text.trim();
    if (content.isEmpty) return; // Jangan post jika kosong

    final currentAuthUser = firebaseAuth.currentUser;
    if (currentAuthUser == null) {
      Get.snackbar("Error", "Anda harus login untuk berkomentar.");
      return;
    }

    isPostingComment.value = true;

    // Ambil data user saat ini (untuk username & foto profil)
    final userDataResult = await getUserDataUseCase(
      GetUserDataParams(currentAuthUser.uid),
    );
    final UserEntity? currentUser = userDataResult.fold((l) => null, (r) => r);

    if (currentUser == null) {
      isPostingComment.value = false;
      Get.snackbar("Error", "Gagal mengambil data user.");
      return;
    }

    // Buat objek CommentEntity baru
    final newComment = CommentEntity(
      id: '', // ID akan dibuat oleh Firestore
      postId: postId,
      authorId: currentUser.uid,
      authorUsername: currentUser.username,
      authorProfileUrl:
          currentUser.profileImageUrl, // (Masih null, tapi tidak apa-apa)
      content: content,
      createdAt: DateTime.now(),
      likes: [],
      parentId: replyingTo.value?.id,
    );

    // Panggil UseCase
    final result = await addCommentUseCase(
      AddCommentParams(comment: newComment),
    );

    isPostingComment.value = false;

    result.fold(
      (failure) {
        Get.snackbar("Error", failure.message);
      },
      (success) {
        textController.clear(); // Bersihkan field input
        // Refresh feed agar jumlah komentar di feed update
        cancelReply();
        EventBus.fireFeed(FetchFeedEvent());
      },
    );
  }

  void toggleLike(String commentId) {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar("Error", "Anda harus login untuk menyukai komentar.");
      return;
    }

    // Panggil UseCase
    // Kita tidak perlu 'await' karena 'fetchComments' (Stream)
    // akan otomatis mendeteksi perubahan dan me-refresh UI
    toggleLikeCommentUseCase(
      ToggleLikeCommentParams(
        postId: postId, // 'postId' dari constructor controller
        commentId: commentId,
        userId: userId,
      ),
    );
  }
  
  void deleteComment(String commentId) async {
    Get.dialog(
      AlertDialog(
        title: Text("Hapus Komentar?"),
        content: Text("Komentar ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Batal")),
          TextButton(
            onPressed: () async {
              Get.back(); // Tutup dialog
              
              // Panggil UseCase
              final result = await deleteCommentUseCase(
                DeleteCommentParams(postId: postId, commentId: commentId)
              );

              result.fold(
                (failure) => Get.snackbar("Error", failure.message),
                (success) => Get.snackbar("Sukses", "Komentar dihapus"),
              );
              // Tidak perlu refresh manual karena kita pakai Stream di fetchComments
            },
            child: Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }
  

  @override
  void onClose() {
    _commentsSubscription?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
