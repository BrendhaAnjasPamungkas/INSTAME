import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

// --- CONTROLLER KHUSUS VIDEO ---
class FeedVideoController extends GetxController {
  final String url;
  late VideoPlayerController videoController;
  
  var isInitialized = false.obs;
  var isPlaying = false.obs;

  FeedVideoController(this.url);

  @override
  void onInit() {
    super.onInit();
    // Paksa HTTPS agar aman di web/mobile
    String secureUrl = url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;
    
    videoController = VideoPlayerController.networkUrl(Uri.parse(secureUrl))
      ..initialize().then((_) {
        isInitialized.value = true;
        videoController.setLooping(true); // Loop video di feed
      });
  }
  
  void togglePlay() {
    if (videoController.value.isPlaying) {
      videoController.pause();
      isPlaying.value = false;
    } else {
      videoController.play();
      isPlaying.value = true;
    }
  }

  @override
  void onClose() {
    videoController.dispose(); // Bersihkan memori saat scroll lewat
    super.onClose();
  }
}

// --- WIDGET STATELESS ---
class FeedVideoPlayer extends StatelessWidget {
  final String url;

  const FeedVideoPlayer({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan URL sebagai TAG agar setiap video punya controller sendiri-sendiri
    final controller = Get.put(FeedVideoController(url), tag: url);

    return Obx(() {
      if (!controller.isInitialized.value) {
        return Container(
          height: 300, // Tinggi sementara saat loading
          color: Colors.grey[900],
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      return GestureDetector(
        onTap: () => controller.togglePlay(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            AspectRatio(
              aspectRatio: controller.videoController.value.aspectRatio,
              child: VideoPlayer(controller.videoController),
            ),
            
            // Ikon Play (Muncul jika pause)
            if (!controller.isPlaying.value)
              Container(
                decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                padding: EdgeInsets.all(12),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
              ),
          ],
        ),
      );
    });
  }
}