import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
// --- IMPORT BARU ---
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/controllers/upload_story_controller.dart';
import 'package:instagram/presentation/pages/comments_page.dart';
import 'package:instagram/presentation/controllers/feed_video_player.dart';
import 'package:instagram/presentation/pages/profile_page.dart';
import 'package:instagram/presentation/pages/story_view_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/story_ring_widget.dart';

// --- IMPORT BARU ---
class FeedPage extends StatelessWidget {
  FeedPage({super.key});

  final FeedController controller = Get.put(
    FeedController(),
    tag: "feedController",
  );

  // Controller untuk Story Rings
  final StoryController storyController = Get.put(
    StoryController(),
    tag: "storyController",
  );
  final UploadStoryController uploadStoryController = Get.put(
    UploadStoryController(),
    tag: "UploadStoryController",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/logoinsta.png",
          color: Colors.white,
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          // --- TOMBOL TAMBAH STORY (DI APPBAR) ---
          IconButton(
            icon: Icon(Icons.add_box_outlined, size: 28),
            onPressed: () {
              // Panggil fungsi upload
              uploadStoryController.pickAndUploadStory();
            },
          ),

          // ---------------------------------------
          W.gap(width: 10),
          IconButton(
            icon: Icon(Icons.favorite_border, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, size: 28),
            onPressed: () {},
          ),
          W.gap(width: 10),
        ],
      ),
      // --- PERUBAHAN BODY: Gunakan Column ---
      body: Column(
        children: [
          // --- 1. WIDGET STORY RINGS ---
          // --- 1. WIDGET STORY RINGS ---
          Container(
            height: 110,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Obx(() {
              if (storyController.isLoading.value) {
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemCount: storyController.stories.length + 1,
                itemBuilder: (context, index) {
                  // Tombol "Story Anda"
                  if (index == 0) {
                    return _buildYourStoryButton(context);
                  }

                  // Cincin Story Orang Lain
                  final story = storyController.stories[index - 1];

                  // Gunakan ID yang konsisten
                  final String uniqueStoryId =
                      "${story.id}_${story.lastStoryAt.millisecondsSinceEpoch}";

                  // --- INI PERBAIKANNYA: Obx MEMBUNGKUS LOGIKA CEK ---
                  return Obx(() {
                    // Cek di DALAM Obx agar reaktif
                    final bool isViewed = storyController.viewedStoryIds
                        .contains(uniqueStoryId);

                    return StoryRingWidget(
                      username: story.username,
                      profileImageUrl: story.profileImageUrl,
                      hasUnviewedStories:
                          !isViewed, // Jika sudah dilihat, false (abu-abu)
                      onTap: () {
                        storyController.markAsViewed(uniqueStoryId);
                        Get.to(
                          () => StoryViewPage(
                            userId: story.id,
                            username: story.username,
                            userProfileUrl: story.profileImageUrl,
                          ),
                        );
                      },
                    );
                  });
                  // --------------------------------------------------
                },
              );
            }),
          ),
          Divider(height: 1, color: Colors.grey[800]),
          // --- AKHIR STORY RINGS ---

          // --- 2. FEED POSTINGAN (DI DALAM EXPANDED) ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              if (controller.posts.isEmpty) {
                return Center(
                  child: W.text(
                    data: "Ikuti seseorang untuk melihat postingan.",
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.posts.length,
                itemBuilder: (context, index) {
                  final post = controller.posts[index];

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
                              // FOTO PROFIL PENULIS
                              GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => ProfilePage(userId: post.authorId),
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    shape: BoxShape.circle,
                                  ),

                                  child: ClipOval(
                                    child:
                                        (post.authorProfileUrl != null &&
                                            post.authorProfileUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: post.authorProfileUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: Colors.grey[900],
                                                ),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                                  Icons.person,
                                                  color: Colors.grey[600],
                                                ),
                                            key: ValueKey(
                                              post.authorProfileUrl!,
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[900],
                                            child: Icon(
                                              Icons.person,
                                              size: 20,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              W.gap(width: 8),

                              // USERNAME PENULIS
                              GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => ProfilePage(userId: post.authorId),
                                  );
                                },
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
                                  _showPostOptions(
                                    context,
                                    post.id,
                                    post.authorId,
                                    controller,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // --- GAMBAR POSTINGAN ---
                        // ... di dalam ListView.builder (untuk setiap post)

                        // --- Bagian utama konten postingan (gambar/video) ---
                        // Area ini adalah yang harusnya menampilkan gambar atau video
                        if (post.type == PostType.video)
                          FeedVideoPlayer(
                            url: post.imageUrl,
                          ) // <-- PASTIKAN INI DI SINI
                        else
                          CachedNetworkImage(
                            imageUrl: post.imageUrl,
                            width: Get.width,
                            height: Get.width,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[800]),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                        // ----------------------------------------------------

                        // ... (bagian ikon like, komen, share, caption, dll)
                        // --- TOMBOL LIKE/COMMENT ---
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
                                color:
                                    post.likes.contains(
                                      controller.currentUserId,
                                    )
                                    ? Colors.red
                                    : Colors.white,
                                onPressed: () => controller.toggleLike(post.id),
                              ),
                              W.gap(width: 4),
                              IconButton(
                                icon: Icon(Icons.chat_bubble_outline),
                                onPressed: () {
                                  Get.to(() => CommentsPage(postId: post.id));
                                },
                              ),
                              W.gap(width: 4),
                              IconButton(
                                icon: Icon(Icons.send_outlined), // Share icon
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),

                        // --- JUMLAH LIKE ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: W.text(
                            data: "${post.likes.length} Suka",
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        W.gap(height: 4),

                        // --- CAPTION ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: W.richText(
                            defaultColor: Colors.white,
                            children: [
                              W.textSpan(
                                text: post.authorUsername,
                                fontWeight: FontWeight.bold,
                              ),
                              W.textSpan(text: " ${post.caption}"),
                            ],
                          ),
                        ),
                        W.gap(height: 16),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI HELPER BARU UNTUK "STORY ANDA" ---
  // (Tambahkan ini di dalam class FeedPage)
  Widget _buildYourStoryButton(BuildContext context) {
    return Obx(() {
      final myStory = storyController.myStory.value;

      if (myStory != null) {
        // ID Unik
        final String uniqueId =
            "${myStory.id}_${myStory.lastStoryAt.millisecondsSinceEpoch}";

        // --- PERBAIKAN: Cek di DALAM Obx ---
        final bool isViewed = storyController.viewedStoryIds.contains(uniqueId);
        // -----------------------------------

        return Column(
          children: [
            StoryRingWidget(
              username: "Cerita Anda",
              profileImageUrl: myStory.profileImageUrl,
              hasUnviewedStories: !isViewed, // Reaktif
              onTap: () {
                storyController.markAsViewed(uniqueId);
                Get.to(
                  () => StoryViewPage(
                    userId: myStory.id,
                    username: "Cerita Anda",
                    userProfileUrl: myStory.profileImageUrl,
                  ),
                );
              },
            ),
          ],
        );
      }
      // KONDISI 2: Saya BELUM punya story (Tampilan Lama dengan Ikon +)
      else {
        // Kita butuh foto profil user saat ini untuk ditampilkan pudar
        // Kita bisa ambil dari FeedController (yang mungkin sudah punya data user)
        // Atau sementara pakai placeholder/controller.currentUserId

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Upload story baru
                  uploadStoryController.pickAndUploadStory();
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Foto profil (Placeholder/Abu-abu)
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[900], // Background
                      ),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey[600],
                      ),
                      // TODO: Idealnya ambil foto profil user dari AuthController/Local Storage
                    ),
                    // Ikon tambah (+)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              W.gap(height: 4),
              W.text(
                data: "Cerita Anda",
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ],
          ),
        );
      }
    });
  }

  // (Fungsi _showPostOptions Anda tetap di sini)
  void _showPostOptions(
    BuildContext context,
    String postId,
    String authorId,
    FeedController controller,
  ) {
    final bool isMyPost = authorId == controller.currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opsi Hapus
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

              // Opsi Lihat Profil
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
