import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/controllers/upload_story_controller.dart';
import 'package:instagram/presentation/pages/activity_pages.dart';
import 'package:instagram/presentation/pages/inbox_pages.dart';
import 'package:instagram/presentation/pages/story_view_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/post_card.dart';
import 'package:instagram/presentation/widgets/story_ring_widget.dart';
import 'package:instagram/presentation/widgets/universal_image.dart'; // Import UniversalImage

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
          IconButton(
            icon: Icon(Icons.favorite_border, size: 28),
            onPressed: () => Get.to(() => ActivityPage()),
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, size: 28),
            onPressed: () => Get.to(() => InboxPage()),
          ),
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
          // 1. Loading State
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. Data Postingan
          final posts = controller.posts;

          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            // Jumlah item = Jumlah Post + 1 (untuk area Story di paling atas)
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              // --- A. ITEM PERTAMA (INDEX 0) ADALAH STORY SECTION ---
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStorySection(),
                    Divider(height: 1, color: Colors.grey[800]),
                    // Jika tidak ada postingan, tampilkan pesan di bawah story
                    if (posts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: Center(
                          child: W.text(
                            data: "Ikuti seseorang untuk melihat postingan.",
                          ),
                        ),
                      ),
                  ],
                );
              }

              // --- B. ITEM SELANJUTNYA ADALAH POSTINGAN ---
              final post = posts[index - 1];
              return PostCard(post: post);
            },
          );
        }),
      ),
    );
  }

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

      // KONDISI 1: SUDAH ADA STORY (Cincin)
      if (myStory != null) {
        final String uniqueId =
            "${myStory.id}_${myStory.lastStoryAt.millisecondsSinceEpoch}";
        final bool isViewed = storyController.viewedStoryIds.contains(uniqueId);

        return StoryRingWidget(
          username: "Cerita Anda",
          profileImageUrl: myStory.profileImageUrl,
          hasUnviewedStories: !isViewed,
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
        );
      } 
      
      // KONDISI 2: BELUM ADA STORY (Tombol +)
      else {
        // Ambil foto profil dari controller
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
                        // --- PERBAIKAN UTAMA DI SINI ---
                        // Gunakan UniversalImage agar aman (https, error handling, dll)
                        child: UniversalImage(
                          imageUrl: myPicUrl,
                          width: 68, 
                          height: 68,
                          isCircle: true, // Agar dipotong bulat
                        ),
                        // -------------------------------
                      ),
                    ),
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