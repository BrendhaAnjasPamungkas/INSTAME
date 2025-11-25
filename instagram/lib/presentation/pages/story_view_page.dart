import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/controllers/story_view_controller.dart';
import 'package:instagram/presentation/controllers/video_story_controller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/universal_image.dart';
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
    // Controller khusus untuk halaman viewer ini
    final StoryViewController controller = Get.put(
      StoryViewController(userId: userId),
      tag: "story_view_$userId",
    );

    // Ambil Global StoryController untuk akses foto profil live (jika story saya)
    final StoryController Scontroller = Get.put(
      StoryController(),
      tag: "story_view_$userId",
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // 1. Loading Data Awal
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        // 2. Data Kosong/Habis
        if (controller.storyItems.isEmpty) return SizedBox.shrink();

        final currentItem = controller.storyItems[controller.currentIndex.value];

        return Stack(
          children: [
            // --- LAYER 1: KONTEN (GAMBAR/VIDEO) ---
            Positioned.fill(
              child: Center(
                child: currentItem.type == StoryType.video
                    ? VideoStoryPlayer(
                        url: currentItem.url,
                        onFinished: () {
                           // Opsional: Pindah otomatis (tapi timer controller sudah handle ini)
                        },
                      )
                    : UniversalImage(
                        imageUrl: currentItem.url,
                        fit: BoxFit.contain,
                      ),
              ),
            ),

            // --- LAYER 2: DETEKSI SENTUHAN (TOUCH LAYER) ---
            // Transparan, ada di atas konten agar bisa di-tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent, 
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  // Tap Kiri (30% layar) -> Mundur
                  if (details.globalPosition.dx < screenWidth * 0.3) {
                    controller.previousStory();
                  } 
                  // Tap Kanan (70% layar) -> Maju
                  else {
                    controller.nextStory();
                  }
                },
                child: Container(color: Colors.transparent), 
              ),
            ),

            // --- LAYER 3: UI OVERLAY (HEADER & PROGRESS) ---
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
                  
                  // Info User
                  Row(
                    children: [
                      // Avatar Reaktif
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
                        child: ClipOval(
                          child: _buildReactiveAvatar(controller.isMine, Scontroller),
                        ),
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
                      
                      // Tombol Hapus (Hanya jika milik sendiri)
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

            // --- LAYER 4: JUMLAH VIEWS (BOTTOM LEFT) ---
            if (controller.isMine)
              Positioned(
                bottom: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () {
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
                            data: "${currentItem.viewedBy.length}",
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

  // Helper untuk Avatar
  Widget _buildReactiveAvatar(bool isMine, StoryController? globalController) {
    if (isMine && globalController != null) {
      return Obx(() {
        return UniversalImage(
          imageUrl: globalController.currentUserProfilePic.value,
          width: 32, height: 32,
          isCircle: true,
        );
      });
    }
    return UniversalImage(
      imageUrl: userProfileUrl,
      width: 32, height: 32,
      isCircle: true,
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours > 0) return "${diff.inHours}j";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Baru saja";
  }
}

// --- WIDGET PEMUTAR VIDEO (Stateless) ---
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