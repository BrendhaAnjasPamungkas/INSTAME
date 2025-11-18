import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/domain/usecase/delete_story_usecase.dart';
import 'package:instagram/domain/usecase/get_story_items_usecase.dart';
import 'package:instagram/domain/usecase/view_story_usecase.dart';
import 'package:instagram/injection_container.dart';
import 'package:video_player/video_player.dart';

class StoryViewController extends GetxController {
  final GetStoryItemsUseCase getStoryItemsUseCase =
      locator<GetStoryItemsUseCase>();
  final ViewStoryUseCase viewStoryUseCase = locator<ViewStoryUseCase>();
  final String userId; // ID pemilik story yang kita lihat
  final DeleteStoryUseCase deleteStoryUseCase = locator<DeleteStoryUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  bool get isMine => userId == firebaseAuth.currentUser?.uid;

  StoryViewController({required this.userId});

  var isLoading = true.obs;
  var storyItems = <StoryItem>[].obs;

  // Index story yang sedang dilihat sekarang (0, 1, 2...)
  var currentIndex = 0.obs;

  // Timer untuk progress bar
  Timer? _timer;
  var progressValue = 0.0.obs; // 0.0 sampai 1.0

  @override
  void onInit() {
    super.onInit();
    fetchStoryItems();
  }

  void fetchStoryItems() {
    isLoading.value = true;

    // Ambil item story (foto-fotonya)
    getStoryItemsUseCase.execute(GetStoryItemsParams(userId: userId)).listen((
      eitherResult,
    ) {
      eitherResult.fold(
        (failure) {
          Get.snackbar("Error", "Gagal memuat story");
          Get.back();
        },
        (items) {
          if (items.isEmpty) {
            Get.back(); // Tidak ada item, tutup
            return;
          }
          storyItems.value = items;
          isLoading.value = false;
          _startTimer(); // Mulai mainkan story pertama
        },
      );
    });
  }

  

void deleteCurrentStory() async {
    // 1. Pause timer
    _timer?.cancel(); 

    // 2. Tampilkan Dialog Konfirmasi DAN simpan hasilnya ke variabel 'confirm'
    final bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text("Hapus Story?"),
        content: Text("Story ini akan dihapus selamanya."),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false), 
            child: Text("Batal")
          ),
          TextButton(
            onPressed: () => Get.back(result: true), 
            child: Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    // 3. Cek hasil konfirmasi
    if (confirm != true) {
      _startTimer(); // Lanjutkan jika batal
      return;
    }

    isLoading.value = true;
    
    final itemToDelete = storyItems[currentIndex.value];
    final currentUserId = firebaseAuth.currentUser!.uid;

    // 4. Panggil Use Case
    // CATATAN: Jika DeleteStoryParams Anda menggunakan positional arguments
    // (tanpa {} di constructor), hapus 'storyId:' dan 'authorId:' di bawah ini.
    final result = await deleteStoryUseCase(
      DeleteStoryParams(
        storyId: itemToDelete.id, 
        authorId: currentUserId,
      )
    );

    isLoading.value = false;

    result.fold(
      (failure) {
        Get.snackbar("Error", "Gagal menghapus story");
        _startTimer();
      },
      (success) {
        storyItems.removeAt(currentIndex.value);

        if (storyItems.isEmpty) {
          Get.back(); // Tutup jika habis
          // Opsional: Refresh feed
        } else {
          if (currentIndex.value >= storyItems.length) {
             currentIndex.value = storyItems.length - 1;
          }
          _startTimer();
        }
      }
    );
  }

  void _startTimer() {
    _timer?.cancel();
    progressValue.value = 0.0;

    // Timer berjalan setiap 50ms selama 5 detik
    final currentItem = storyItems[currentIndex.value];
    final currentUserId = firebaseAuth.currentUser!.uid;
    const duration = Duration(seconds: 5);
    const step = Duration(milliseconds: 50);
    int totalSteps = duration.inMilliseconds ~/ step.inMilliseconds;
    int currentStep = 0;

    if (!isMine && !currentItem.viewedBy.contains(currentUserId)) {
      // Catat view di background (fire and forget)
      viewStoryUseCase(ViewStoryParams(storyId: currentItem.id, viewerId: currentUserId));
    }

    _timer = Timer.periodic(step, (timer) {
      currentStep++;
      progressValue.value = currentStep / totalSteps;

      if (currentStep >= totalSteps) {
        // Waktu habis, lanjut ke story berikutnya
        nextStory();
      }
    });
  }

  void nextStory() {
    if (currentIndex.value < storyItems.length - 1) {
      // Masih ada story selanjutnya
      currentIndex.value++;
      _startTimer(); // Reset timer untuk story baru
    } else {
      // Sudah story terakhir, tutup viewer
      _timer?.cancel();
      Get.back();
    }
  }

  void previousStory() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _startTimer();
    } else {
      // Jika di awal, restart timer saja (atau bisa tutup)
      _startTimer();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
  
}

class VideoStoryPlayer extends StatefulWidget {
  final String url;
  final VoidCallback onFinished;

  const VideoStoryPlayer({required this.url, required this.onFinished});

  @override
  _VideoStoryPlayerState createState() => _VideoStoryPlayerState();
}

class _VideoStoryPlayerState extends State<VideoStoryPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        widget.onFinished(); // Video selesai
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
  
}
