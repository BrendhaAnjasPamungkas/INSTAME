import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/domain/usecase/delete_story_usecase.dart';
import 'package:instagram/domain/usecase/get_story_items_usecase.dart';
import 'package:instagram/domain/usecase/view_story_usecase.dart';
import 'package:instagram/injection_container.dart';

class StoryViewController extends GetxController {
  final GetStoryItemsUseCase getStoryItemsUseCase = locator<GetStoryItemsUseCase>();
  final DeleteStoryUseCase deleteStoryUseCase = locator<DeleteStoryUseCase>();
  final ViewStoryUseCase viewStoryUseCase = locator<ViewStoryUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  
  final String userId;

  StoryViewController({required this.userId});

  var isLoading = true.obs;
  var storyItems = <StoryItem>[].obs;
  var currentIndex = 0.obs;
  var progressValue = 0.0.obs;
  Timer? _timer;

  bool get isMine => userId == firebaseAuth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    fetchStoryItems();
  }

  void fetchStoryItems() {
    isLoading.value = true;
    
    // --- PENGAMAN TIMEOUT ---
    // Jika 5 detik tidak ada respon, tutup viewer
    Timer(Duration(seconds: 5), () {
      if (isLoading.value) {
        Get.back();
        Get.snackbar("Error", "Koneksi lambat atau data story rusak.");
      }
    });
    // ------------------------

    getStoryItemsUseCase.execute(GetStoryItemsParams(userId: userId))
      .listen((eitherResult) {
        
        eitherResult.fold(
          (failure) {
            isLoading.value = false;
            Get.snackbar("Error", "Gagal memuat story: ${failure.message}");
            Get.back();
          },
          (items) {
            isLoading.value = false;
            
            // Jika kosong (misal sudah expire semua), tutup
            if (items.isEmpty) {
              Get.back();
              return;
            }
            
            // Urutkan biar rapi (opsional, karena di DB sudah sort)
            // items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            storyItems.value = items;
            
            // Mulai timer hanya jika belum jalan
            if (_timer == null || !_timer!.isActive) {
               _startTimer();
            }
          }
        );
      });
  }

  void _startTimer() {
    _timer?.cancel();
    progressValue.value = 0.0;

    if (storyItems.isEmpty || currentIndex.value >= storyItems.length) return;

    final currentItem = storyItems[currentIndex.value];
    final currentUserId = firebaseAuth.currentUser?.uid;

    // Catat View
    if (!isMine && currentUserId != null && !currentItem.viewedBy.contains(currentUserId)) {
      viewStoryUseCase(ViewStoryParams(storyId: currentItem.id, viewerId: currentUserId));
    }

    const duration = Duration(seconds: 5);
    const step = Duration(milliseconds: 50);
    int totalSteps = duration.inMilliseconds ~/ step.inMilliseconds;
    int currentStep = 0;

    _timer = Timer.periodic(step, (timer) {
      currentStep++;
      progressValue.value = currentStep / totalSteps;

      if (currentStep >= totalSteps) {
        nextStory();
      }
    });
  }

  void nextStory() {
    if (currentIndex.value < storyItems.length - 1) {
      currentIndex.value++;
      _startTimer();
    } else {
      _timer?.cancel();
      Get.back(); 
    }
  }

  void previousStory() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _startTimer();
    } else {
      _startTimer(); // Restart story pertama
    }
  }

  void deleteCurrentStory() async {
    _timer?.cancel(); 
    final itemToDelete = storyItems[currentIndex.value];
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text("Hapus Story?"),
        content: Text("Story ini akan dihapus selamanya."),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text("Batal")),
          TextButton(onPressed: () => Get.back(result: true), child: Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) {
      _startTimer();
      return;
    }

    isLoading.value = true;
    final currentUserId = firebaseAuth.currentUser!.uid;

    final result = await deleteStoryUseCase(
      DeleteStoryParams(storyId: itemToDelete.id, authorId: currentUserId)
    );

    isLoading.value = false;

    result.fold(
      (failure) {
        Get.snackbar("Error", "Gagal menghapus story");
        _startTimer();
      },
      (success) {
        // Hapus lokal
        storyItems.removeAt(currentIndex.value);
        
        if (storyItems.isEmpty) {
          Get.back(); 
        } else {
          if (currentIndex.value >= storyItems.length) {
             currentIndex.value = storyItems.length - 1;
          }
          _startTimer();
        }
      }
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}