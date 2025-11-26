import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/comments_controller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentsPage extends StatelessWidget {
  final String postId;

  const CommentsPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CommentsController controller = Get.put(
      CommentsController(postId: postId),
    );

    return Scaffold(
      appBar: AppBar(title: W.text(data: "Komentar")),
      body: Column(
        children: [
          // 1. Daftar Komentar
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              if (controller.comments.isEmpty) {
                return Center(child: W.text(data: "Belum ada komentar."));
              }

              return ListView.builder(
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  final String currentUserId =
                      controller.firebaseAuth.currentUser?.uid ?? "";
                  final bool isLiked = comment.likes.contains(currentUserId);
                  final bool isMyComment = comment.authorId == currentUserId;

                  return GestureDetector(
                    onLongPress: () {
                      if (isMyComment) {
                        controller.deleteComment(comment.id);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: comment.authorProfileUrl != null
                                ? CachedNetworkImageProvider(
                                    comment.authorProfileUrl!)
                                : null,
                            child: comment.authorProfileUrl == null
                                ? Icon(Icons.person,
                                    size: 18, color: Colors.grey[600])
                                : null,
                          ),
                          W.gap(width: 12),

                          // Konten Teks & Tombol Balas
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username & Isi Komentar
                                W.richText(
                                  children: [
                                    W.textSpan(
                                      text: "${comment.authorUsername} ",
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // Pastikan putih
                                      fontSize: 13,
                                    ),
                                    W.textSpan(
                                      text: "\n${comment.content}",
                                      color: Colors.white, // Pastikan putih
                                      fontSize: 13,
                                    ),
                                  ],
                                ),
                                W.gap(height: 4),

                                // Baris Bawah: Waktu & Tombol "Balas"
                                Row(
                                  children: [
                                    W.text(
                                      data:
                                          "${comment.createdAt.toLocal().hour}:${comment.createdAt.toLocal().minute.toString().padLeft(2, '0')}",
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    W.gap(width: 16),

                                    // --- TOMBOL BALAS ---
                                    GestureDetector(
                                      onTap: () {
                                        controller.startReplying(comment);
                                      },
                                      child: W.text(
                                        data: "Balas",
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // --------------------
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Tombol Like Komentar
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 16,
                            ),
                            onPressed: () => controller.toggleLike(comment.id),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // --- AREA INPUT DENGAN BANNER REPLY ---
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, color: Colors.grey[800]),

              // 1. Banner "Membalas @user"
              Obx(() {
                if (controller.replyingTo.value != null) {
                  return Container(
                    color: Colors.grey[900],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        W.text(
                          data:
                              "Membalas ${controller.replyingTo.value!.authorUsername}",
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => controller.cancelReply(),
                          child:
                              Icon(Icons.close, size: 16, color: Colors.white),
                        )
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),

              // 2. Input Field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Foto Profil Saya
                    Obx(() {
                      final String myPicUrl =
                          controller.currentUserProfilePic.value;
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: (myPicUrl.isNotEmpty)
                            ? CachedNetworkImageProvider(myPicUrl)
                            : null,
                        child: (myPicUrl.isEmpty)
                            ? Icon(Icons.person,
                                size: 18, color: Colors.grey[600])
                            : null,
                      );
                    }),

                    W.gap(width: 12),

                    Expanded(
                      child: W.textField(
                        controller: controller.textController,
                        focusNode: controller.focusNode, // <-- Gunakan FocusNode
                        hint: W.text(
                          data: "Tambahkan komentar...",
                          color: Colors.grey[400],
                        ),
                        fillColor: Colors.transparent,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Obx(
                      () => controller.isPostingComment.value
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.send, color: Colors.blue),
                              onPressed: () {
                                controller.postComment();
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}