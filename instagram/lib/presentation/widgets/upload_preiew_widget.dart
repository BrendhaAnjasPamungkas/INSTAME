import 'dart:io'; // Wajib untuk File
import 'package:flutter/foundation.dart'; // Wajib untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:video_player/video_player.dart';

// --- 1. CONTROLLER KHUSUS ---
class UploadPreviewController extends GetxController {
  final XFile file;
  final PostType type;

  VideoPlayerController? videoController;
  var isVideoInitialized = false.obs;

  UploadPreviewController({required this.file, required this.type});

  @override
  void onInit() {
    super.onInit();
    if (type == PostType.video) {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    try {
      // --- PERBAIKAN DI SINI (DETEKSI PLATFORM) ---
      if (kIsWeb) {
        // WEB: Gunakan networkUrl (Blob URL)
        videoController = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        // HP (Android/iOS): Gunakan file (Path Lokal)
        videoController = VideoPlayerController.file(File(file.path));
      }
      // -------------------------------------------

      await videoController!.initialize();
      videoController!.setLooping(true);
      videoController!.setVolume(1.0);
      videoController!.play();
      
      isVideoInitialized.value = true;
    } catch (e) {
      print("Error initializing preview video: $e");
    }
  }

  @override
  void onClose() {
    videoController?.pause(); 
    videoController?.dispose();
    super.onClose();
  }
}

// --- 2. WIDGET STATELESS ---
class UploadPreviewWidget extends StatelessWidget {
  final XFile file;
  final PostType type;

  const UploadPreviewWidget({
    Key? key, 
    required this.file, 
    required this.type
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String tag = file.path;

    return GetBuilder<UploadPreviewController>(
      tag: tag,
      init: UploadPreviewController(file: file, type: type),
      dispose: (_) {
        Get.delete<UploadPreviewController>(tag: tag);
      },
      builder: (controller) {
        // --- TAMPILAN VIDEO ---
        if (type == PostType.video) {
          return Obx(() {
            if (!controller.isVideoInitialized.value) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            }
            return AspectRatio(
              aspectRatio: controller.videoController!.value.aspectRatio,
              child: VideoPlayer(controller.videoController!),
            );
          });
        } 
        
        // --- TAMPILAN GAMBAR (PERBAIKAN DI SINI) ---
        else {
          if (kIsWeb) {
            // Web: Image.network (Blob URL)
            return Image.network(file.path, fit: BoxFit.cover, width: double.infinity);
          } else {
            // HP: Image.file (Path Lokal) - INI YANG BIKIN ERROR KEMARIN
            return Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity);
          }
        }
      },
    );
  }
}