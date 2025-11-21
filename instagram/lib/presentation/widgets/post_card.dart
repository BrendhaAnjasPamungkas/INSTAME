import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
import 'package:instagram/presentation/controllers/feed_video_player.dart';
import 'package:instagram/presentation/pages/comments_page.dart';
import 'package:instagram/presentation/pages/profile_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/universal_image.dart'; // <-- Gunakan ini

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FeedController controller = Get.find<FeedController>(tag: "feedController");

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER POSTINGAN ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => ProfilePage(userId: post.authorId)),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
                    
                    // 1. PENGGUNAAN UniversalImage UNTUK AVATAR
                    child: UniversalImage(
                      imageUrl: post.authorProfileUrl,
                      width: 36, height: 36,
                      isCircle: true,
                    ),
                    // -----------------------------------------
                  ),
                ),
                W.gap(width: 8),
                GestureDetector(
                  onTap: () => Get.to(() => ProfilePage(userId: post.authorId)),
                  child: W.text(
                    data: post.authorUsername,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    _showPostOptions(context, post.id, post.authorId, controller);
                  },
                ),
              ],
            ),
          ),

          // --- KONTEN UTAMA ---
          if (post.type == PostType.video)
            SizedBox(
              width: Get.width,
              height: Get.width, // Rasio 1:1
              child: FeedVideoPlayer(url: post.imageUrl),
            )
          else
            // 2. PENGGUNAAN UniversalImage UNTUK FOTO POSTINGAN
            // Ini menggantikan kode CachedNetworkImage yang panjang dan ribet
            UniversalImage(
              imageUrl: post.imageUrl,
              width: Get.width,
              height: Get.width, // Rasio 1:1
              fit: BoxFit.cover,
            ),
            // --------------------------------------------------

          // --- TOMBOL AKSI ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likes.contains(controller.currentUserId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  color: post.likes.contains(controller.currentUserId)
                      ? Colors.red
                      : Colors.white,
                  onPressed: () => controller.toggleLike(post.id),
                ),
                W.gap(width: 4),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline),
                  onPressed: () => Get.to(() => CommentsPage(postId: post.id)),
                ),
                W.gap(width: 4),
                IconButton(
                  icon: Icon(Icons.send_outlined),
                  onPressed: () {
                    controller.sharePost(
                      post.caption,
                      post.imageUrl,
                      post.type == PostType.video,
                    );
                  },
                ),
              ],
            ),
          ),

          // --- CAPTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                W.text(
                  data: "${post.likes.length} Suka",
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                W.gap(height: 4),
                W.richText(
                  defaultColor: Colors.white,
                  children: [
                    W.textSpan(
                      text: post.authorUsername,
                      fontWeight: FontWeight.bold,
                    ),
                    W.textSpan(text: " ${post.caption}"),
                  ],
                ),
              ],
            ),
          ),
          W.gap(height: 16),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context, String postId, String authorId, FeedController controller) {
    final bool isMyPost = authorId == controller.currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMyPost)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: W.text(data: "Hapus", color: Colors.red),
                  onTap: () {
                    Navigator.pop(context);
                    Get.defaultDialog(
                      title: "Hapus Postingan?",
                      middleText: "Tindakan ini tidak bisa dibatalkan.",
                      textConfirm: "Hapus",
                      textCancel: "Batal",
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        Get.back();
                        controller.deletePost(postId);
                      },
                    );
                  },
                ),
              ListTile(
                leading: Icon(Icons.person),
                title: W.text(data: "Lihat Profil"),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => ProfilePage(userId: authorId));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}