import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/presentation/controllers/story_view_controller.dart';
import 'package:instagram/presentation/controllers/video_story_controller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:video_player/video_player.dart';

class StoryViewPage extends StatelessWidget {
  final String userId;
  final String username;
  final String? userProfileUrl;

  const StoryViewPage({
    Key? key,
    required this.userId,
    required this.username,
    this.userProfileUrl,
  }) : super(key: key);

 @override
  Widget build(BuildContext context) {
    final StoryViewController controller = Get.put(
      StoryViewController(userId: userId),
      tag: "story_view_$userId",
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.storyItems.isEmpty) return SizedBox.shrink();

        final currentItem = controller.storyItems[controller.currentIndex.value];

        return Stack(
          children: [
            // --- LAYER 1: KONTEN (GAMBAR/VIDEO) ---
            // Berada di paling bawah
            Positioned.fill(
              child: Center(
                child: currentItem.type == StoryType.video
                    ? VideoStoryPlayer(
                        url: currentItem.url,
                        onFinished: () {
                           controller.nextStory(); 
                        },
                      )
                    : CachedNetworkImage(
                        imageUrl: currentItem.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white),
                      ),
              ),
            ),

            // --- LAYER 2: DETEKSI SENTUHAN (TOUCH LAYER) ---
            // Berada DI ATAS konten, transparan, khusus untuk menangkap tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent, // Wajib: agar area kosong tetap bisa diklik
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  // Logika Tap Kiri/Kanan
                  if (details.globalPosition.dx < screenWidth * 0.3) {
                    controller.previousStory();
                  } else {
                    controller.nextStory();
                  }
                },
                // Container transparan agar bisa di-klik
                child: Container(color: Colors.transparent), 
              ),
            ),

            // --- LAYER 3: UI OVERLAY (Progress Bar & Info) ---
            // Berada di paling atas agar tidak tertutup gesture detector
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  // Progress Bars
                  Row(
                    children: List.generate(controller.storyItems.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Obx(() {
                            double value = 0.0;
                            if (index < controller.currentIndex.value) {
                              value = 1.0;
                            } else if (index == controller.currentIndex.value) {
                              value = controller.progressValue.value;
                            }

                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 3,
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                  
                  W.gap(height: 10),
                  
                  // Info User & Tombol Close
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: (userProfileUrl != null) 
                            ? CachedNetworkImageProvider(userProfileUrl!) 
                            : null,
                      ),
                      W.gap(width: 8),
                      W.text(
                        data: username,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      W.gap(width: 8),
                      W.text(
                        data: _getTimeAgo(currentItem.createdAt),
                        color: Colors.white70,
                        fontSize: 12
                      ),
                      Spacer(),
                      // Tombol Hapus (Jika milik sendiri)
                      if (controller.isMine)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () => controller.deleteCurrentStory(),
                        ),
                      // Tombol Tutup
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      )
                    ],
                  )
                ],
              ),
            ),
            if (controller.isMine)
              Positioned(
                bottom: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                     // TODO: Nanti bisa buka list orang yg melihat
                     Get.snackbar("Views", "${currentItem.viewedBy.length} orang melihat");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                          W.gap(width: 8),
                          W.text(
                            data: "${currentItem.viewedBy.length}", // TAMPILKAN ANGKA
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours > 0) return "${diff.inHours}j";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Baru saja";
  }
}

class VideoStoryPlayer extends StatelessWidget {
  final String url;
  final VoidCallback onFinished;

  const VideoStoryPlayer({
    Key? key,
    required this.url,
    required this.onFinished,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan URL sebagai tag agar setiap video punya controller sendiri
    final controller = Get.put(
      VideoStoryController(url: url, onFinished: onFinished),
      tag: url,
    );

    return Obx(() {
      if (!controller.isInitialized.value || controller.isBuffering.value) {
        return Center(child: CircularProgressIndicator(color: Colors.white));
      }

      return Center(
        child: AspectRatio(
          aspectRatio: controller.videoPlayerController.value.aspectRatio,
          child: VideoPlayer(controller.videoPlayerController),
        ),
      );
    });
  }
}
