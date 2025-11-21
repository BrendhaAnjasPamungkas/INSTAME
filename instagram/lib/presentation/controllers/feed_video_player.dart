import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class FeedVideoController extends GetxController {
  final String url;
  
  // Nullable controller
  VideoPlayerController? videoController; 
  
  var isInitialized = false.obs;
  var isPlaying = false.obs;
  var isBuffering = false.obs;
  var hasError = false.obs;
  
  String? errorMessage;

  FeedVideoController(this.url);

  @override
  void onInit() {
    super.onInit();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      hasError.value = false; 
      isInitialized.value = false;

      String secureUrl = url.trim();
      if (secureUrl.startsWith('http://')) {
        secureUrl = secureUrl.replaceFirst('http://', 'https://');
      }

      // Dispose controller lama jika ada
      videoController?.dispose();

      videoController = VideoPlayerController.networkUrl(
        Uri.parse(secureUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      // --- PERBAIKAN: Tambahkan '!' karena kita yakin videoController sudah diisi ---
      await videoController!.initialize();
      await videoController!.setLooping(true);
      await videoController!.setVolume(1.0);

      isInitialized.value = true;

      videoController!.addListener(_videoListener);

    } catch (e) {
      print("VIDEO INIT GAGAL: $e");
      hasError.value = true;
      errorMessage = e.toString();
    }
  }

  void _videoListener() {
    // Cek null safety
    if (videoController == null || isClosed) return;
    
    if (isInitialized.value) {
      // --- PERBAIKAN: Tambahkan '!' di sini juga ---
      if (isPlaying.value != videoController!.value.isPlaying) {
        isPlaying.value = videoController!.value.isPlaying;
      }
      if (isBuffering.value != videoController!.value.isBuffering) {
        isBuffering.value = videoController!.value.isBuffering;
      }
      
      if (videoController!.value.hasError) {
        print("VIDEO PLAYBACK ERROR: ${videoController!.value.errorDescription}");
        hasError.value = true;
        videoController!.removeListener(_videoListener);
      }
    }
  }
  
  void retryLoad() {
    _initializeVideo();
  }

  void togglePlay() async {
    if (!isInitialized.value || hasError.value || videoController == null) return;

    try {
      // --- PERBAIKAN: Tambahkan '!' ---
      if (videoController!.value.isPlaying) {
        await videoController!.pause();
        isPlaying.value = false; 
      } else {
        if (videoController!.value.position >= videoController!.value.duration) {
           await videoController!.seekTo(Duration.zero);
        }
        await videoController!.play();
        isPlaying.value = true; 
      }
    } catch (e) {
      print("Video Toggle Error: $e");
    }
  }

  @override
  void onClose() {
    videoController?.removeListener(_videoListener);
    videoController?.dispose();
    super.onClose();
  }
}

class FeedVideoPlayer extends StatelessWidget {
  final String url;

  const FeedVideoPlayer({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedVideoController(url), tag: url);

    return Obx(() {
      if (controller.hasError.value) {
        return Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[900],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text("Video gagal dimuat", style: TextStyle(color: Colors.white)),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.retryLoad(), 
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
              )
            ],
          ),
        );
      }

      if (!controller.isInitialized.value || controller.videoController == null) {
        return Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[900],
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      return AspectRatio(
        // --- PERBAIKAN: Tambahkan '!' ---
        aspectRatio: controller.videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller.videoController!),
            
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, 
                onTap: () => controller.togglePlay(),
                child: Container(
                  color: Colors.transparent, 
                  child: Center(
                    child: _buildOverlayIcon(controller),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOverlayIcon(FeedVideoController controller) {
    if (controller.isBuffering.value) {
      return CircularProgressIndicator(color: Colors.white);
    }
    
    if (!controller.isPlaying.value) {
      return Container(
        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        padding: EdgeInsets.all(12),
        child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
      );
    }

    return SizedBox.shrink();
  }
}