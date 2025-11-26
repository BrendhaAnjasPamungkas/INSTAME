import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
import 'package:instagram/presentation/controllers/inbox_controller.dart';
import 'package:instagram/presentation/controllers/notification_controller.dart';
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/controllers/upload_story_controller.dart';
import 'package:instagram/presentation/pages/activity_pages.dart';
import 'package:instagram/presentation/pages/inbox_pages.dart';
import 'package:instagram/presentation/pages/story_view_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/post_card.dart';
import 'package:instagram/presentation/widgets/story_ring_widget.dart';
import 'package:instagram/presentation/widgets/universal_image.dart';

class FeedPage extends StatelessWidget {
  FeedPage({super.key});

  final FeedController controller = Get.put(
    FeedController(),
    tag: "feedController",
  );

  final StoryController storyController = Get.put(
    StoryController(),
    tag: "storyController",
  );

  final UploadStoryController uploadStoryController = Get.put(
    UploadStoryController(),
    tag: "UploadStoryController",
  );
  final NotificationController notificationController = Get.put(NotificationController());
  final InboxController inboxController = Get.put(InboxController());

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
          IconButton(
            icon: Icon(Icons.add_box_outlined, size: 28),
            onPressed: () => uploadStoryController.pickAndUploadStory(),
          ),
          W.gap(width: 10),
        Obx(() => RedDotIconButton(
            icon: Icons.favorite_border,
            showBadge: notificationController.hasUnread.value,
            onPressed: () {
              // Matikan badge saat diklik
              notificationController.markAsRead();
              Get.to(() => ActivityPage());
            },
          )),

          // --- TOMBOL DM DENGAN BADGE ---
          Obx(() => RedDotIconButton(
            icon: Icons.send_outlined,
            showBadge: inboxController.hasUnreadMessages.value,
            onPressed: () {
              // Matikan badge saat diklik
              inboxController.markAsRead();
              Get.to(() => InboxPage());
            },
          )),
          W.gap(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.fetchFeed();
          storyController.fetchStories();
          await Future.delayed(Duration(seconds: 1));
        },
        child: Obx(() {
          // 1. Loading State (Hanya muncul sebentar di awal)
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          final posts = controller.posts;

          // --- PERBAIKAN TAMPILAN KOSONG ---
          // Gunakan ListView bahkan saat kosong, agar RefreshIndicator tetap jalan
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            // Jika posts kosong, item count = 2 (Header Story + Pesan Kosong)
            // Jika ada posts, item count = 1 (Header) + jumlah post
            itemCount: posts.isEmpty ? 2 : posts.length + 1,

            itemBuilder: (context, index) {
              // --- A. HEADER: STORY SECTION (Index 0) ---
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStorySection(),
                    Divider(height: 1, color: Colors.grey[800]),
                  ],
                );
              }

              // --- B. JIKA POST KOSONG (Index 1) ---
              if (posts.isEmpty && index == 1) {
                return Container(
                  height: 400, // Tinggi agar terlihat di tengah
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      W.gap(height: 16),
                      W.text(
                        data: "Selamat Datang di Instagram!",
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      W.gap(height: 8),
                      W.text(
                        data:
                            "Ikuti orang lain atau buat postingan\npertama Anda untuk melihatnya di sini.",
                        textAlign: TextAlign.center,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                );
              }

              // --- C. LIST POSTINGAN ---
              // Index data = index UI - 1 (karena index 0 dipakai Header)
              final postIndex = index - 1;
              if (postIndex < posts.length) {
                return PostCard(
                  post: posts[postIndex],
                  controller: controller,
                  storyController: storyController,
                );
              } else {
                return SizedBox.shrink(); // Safety
              }
            },
          );
        }),
      ),
    );
  }

  // ... (Fungsi _buildStorySection dan _buildYourStoryButton TETAP SAMA seperti kode Anda sebelumnya)
  // Pastikan Anda menyalin kembali fungsi _buildStorySection dan _buildYourStoryButton
  // dari kode Anda sebelumnya ke sini agar tidak hilang.

  Widget _buildStorySection() {
    return Container(
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
            if (index == 0) {
              return _buildYourStoryButton(context);
            }

            final story = storyController.stories[index - 1];
            final String uniqueStoryId =
                "${story.id}_${story.lastStoryAt.millisecondsSinceEpoch}";

            return Obx(() {
              final bool isViewed = storyController.viewedStoryIds.contains(
                uniqueStoryId,
              );
              return StoryRingWidget(
                username: story.username,
                profileImageUrl: story.profileImageUrl,
                hasUnviewedStories: !isViewed,
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
          },
        );
      }),
    );
  }

  Widget _buildYourStoryButton(BuildContext context) {
    return Obx(() {
      final myStory = storyController.myStory.value;

      if (myStory != null) {
        final String uniqueId =
            "${myStory.id}_${myStory.lastStoryAt.millisecondsSinceEpoch}";
        final bool isViewed = storyController.viewedStoryIds.contains(uniqueId);

        // Ambil Foto Live
        final String liveProfilePic =
            storyController.currentUserProfilePic.value;

        return Column(
          children: [
            StoryRingWidget(
              username: "Cerita Anda",
              profileImageUrl: liveProfilePic, // Pakai live
              hasUnviewedStories: !isViewed,
              onTap: () {
                storyController.markAsViewed(uniqueId);
                Get.to(
                  () => StoryViewPage(
                    userId: myStory.id,
                    username: "Cerita Anda",
                    userProfileUrl: liveProfilePic, // Pakai live
                  ),
                );
              },
            ),
          ],
        );
      } else {
        final String myPicUrl = storyController.currentUserProfilePic.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => uploadStoryController.pickAndUploadStory(),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[900],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: UniversalImage(
                          imageUrl: myPicUrl,
                          width: 68,
                          height: 68,
                          isCircle: true, // <-- INI KUNCINYA AGAR BULAT
                        ),
                      ),
                    ),

                    // Ikon Tambah (+)
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
}
