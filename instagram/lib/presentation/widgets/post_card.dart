import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
import 'package:instagram/presentation/controllers/feed_video_player.dart';
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/pages/comments_page.dart';
import 'package:instagram/presentation/pages/profile_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/universal_image.dart';

class PostCard extends StatelessWidget {
  final Post post;
  // --- UBAH DI SINI: Terima Controller dari Constructor ---
  final FeedController controller; 
  final StoryController? storyController; 

  const PostCard({
    Key? key, 
    required this.post, 
    required this.controller, 
    this.storyController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get.find SUDAH DIHAPUS DARI SINI

    final bool isMyPost = post.authorId == controller.currentUserId;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => ProfilePage(userId: post.authorId)),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
                    child: _buildSmartAvatar(isMyPost, storyController),
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

          // KONTEN
          // --- KONTEN UTAMA ---
          if (post.type == PostType.video)
            // Hapus SizedBox/Container yang membatasi tinggi.
            // Biarkan FeedVideoPlayer (yang sudah pakai AspectRatio) menentukan tingginya sendiri.
            FeedVideoPlayer(url: post.imageUrl)
          else
            UniversalImage(
              imageUrl: post.imageUrl,
              width: Get.width,
              height: Get.width,
              fit: BoxFit.cover,
            ),

          // TOMBOL AKSI
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Obx(() {
                   final currentPost = controller.posts.firstWhere(
                      (p) => p.id == post.id, orElse: () => post);
                   final isLiked = currentPost.likes.contains(controller.currentUserId);

                   return IconButton(
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                    color: isLiked ? Colors.red : Colors.white,
                    onPressed: () => controller.toggleLike(post.id),
                  );
                }),
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

          // CAPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                   final currentPost = controller.posts.firstWhere(
                      (p) => p.id == post.id, orElse: () => post);
                   return W.text(
                    data: "${currentPost.likes.length} Suka",
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                }),
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

  Widget _buildSmartAvatar(bool isMyPost, StoryController? storyController) {
    if (isMyPost && storyController != null) {
      return Obx(() {
        return UniversalImage(
          imageUrl: storyController.currentUserProfilePic.value,
          width: 36, height: 36,
          isCircle: true,
        );
      });
    } 
    else {
      return UniversalImage(
        imageUrl: post.authorProfileUrl,
        width: 36, height: 36,
        isCircle: true,
      );
    }
  }

  void _showPostOptions(BuildContext context, String postId, String authorId, FeedController controller) {
    final bool isMyPost = authorId == controller.currentUserId;
    // ... (Logika bottom sheet tetap sama)
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