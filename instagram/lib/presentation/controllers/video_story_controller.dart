import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoStoryController extends GetxController {
  final String url;
  final VoidCallback onFinished;
  
  late VideoPlayerController videoPlayerController;
  var isInitialized = false.obs;
  var isBuffering = false.obs;

  VideoStoryController({required this.url, required this.onFinished});

  @override
  void onInit() {
    super.onInit();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Paksa HTTPS
    String secureUrl = url;
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }

    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(secureUrl))
      ..initialize().then((_) {
        isInitialized.value = true;
        videoPlayerController.play();
      });

    // Listener untuk buffering dan selesai
    videoPlayerController.addListener(() {
      isBuffering.value = videoPlayerController.value.isBuffering;

      if (videoPlayerController.value.isInitialized &&
          !videoPlayerController.value.isPlaying &&
          videoPlayerController.value.position >= videoPlayerController.value.duration) {
        onFinished(); // Panggil callback saat selesai
      }
    });
  }

  @override
  void onClose() {
    videoPlayerController.dispose();
    super.onClose();
  }
}