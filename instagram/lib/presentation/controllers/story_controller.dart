import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/story.dart';
import 'package:instagram/domain/usecase/get_story_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import locator

class StoryController extends GetxController {
  // Ambil UseCase dari locator (sesuai arsitektur kita)
  final GetStoriesUseCase getStoriesUseCase = locator<GetStoriesUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();

  // State
  var isLoading = true.obs;
  var stories = <Story>[].obs; // Hanya story orang lain
  final Rx<Story?> myStory = Rx(null); // Story saya sendiri
  var viewedStoryIds = <String>{}.obs;
  StreamSubscription? _logoutSubscription;
  var currentUserProfilePic = "".obs;

  StreamSubscription? _storiesSubscription;
  StreamSubscription? _refreshSubscription;

  @override
  void onInit() {
    super.onInit();
    _refreshSubscription = EventBus.feedStream.listen((event) {
      print("STORY: Menerima sinyal refresh...");
      fetchStories();
    });
    _logoutSubscription = EventBus.logoutStream.listen((event) {
      print("STORY: Logout terdeteksi. Membersihkan status viewed...");

      // Hapus semua ID yang sudah dilihat
      viewedStoryIds.clear();
      firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        print("STORY: User siap. Mengambil story...");
        fetchStories();
      }
    });

      // Opsional: Bersihkan story yang ada agar saat login lagi bersih
      stories.clear();
      myStory.value = null;
    });
    // --
    firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        print("AUTH: User terdeteksi, mengambil story...");
        fetchStories();
      }
    });
  }

  void fetchStories() async {
    isLoading.value = true;

    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null) {
      isLoading.value = false;
      return;
    }

    // --- PERBAIKAN: Bungkus dengan Try-Catch ---
    try {
      await _loadViewedStatusFromLocal(currentUserId);
    } catch (e) {
      print("Error loading SharedPrefs: $e");
      // Lanjut saja meskipun gagal load cache
    }
    // ------------------------------------------
    final userDataResult = await getUserDataUseCase(
      GetUserDataParams(currentUserId),
    );

    userDataResult.fold(
      (failure) {
        isLoading.value = false;
        // print("Gagal ambil user data: ${failure.message}");
      },
      (user) {
        final List<String> allIdsToCheck = List.from(user.following);
        allIdsToCheck.add(user.uid);
        currentUserProfilePic.value = user.profileImageUrl ?? "";
        _storiesSubscription?.cancel();
        // Pastikan Stream ini jalan
        _storiesSubscription = getStoriesUseCase
            .execute(GetStoriesParams(followingIds: allIdsToCheck))
            .listen(
              (eitherResult) {
                // --- PERBAIKAN: Pindahkan isLoading = false ke sini ---
                // Agar saat data masuk, loading langsung hilang
                isLoading.value = false;

                eitherResult.fold(
                  (failure) {
                    print("Gagal ambil stories: ${failure.message}");
                  },
                  (allStories) {
                    final myStoryIndex = allStories.indexWhere(
                      (s) => s.id == currentUserId,
                    );
                    if (myStoryIndex != -1) {
                      myStory.value = allStories[myStoryIndex];
                      allStories.removeAt(myStoryIndex);
                    } else {
                      myStory.value = null;
                    }
                    stories.value = allStories;
                  },
                );
              },
              onError: (e) {
                isLoading.value = false;
                print("Stream Error: $e");
              },
            );
      },
    );
  }

  Future<void> _loadViewedStatusFromLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    // Kunci unik per user: "viewed_stories_abc123"
    final key = 'viewed_stories_$uid';
    final List<String>? savedList = prefs.getStringList(key);

    if (savedList != null) {
      // ignore: invalid_use_of_protected_member
      viewedStoryIds.value = savedList.toSet();
    }
  }

  // Fungsi Public: Menandai dilihat dan menyimpan ke HP
  void markAsViewed(String uniqueStoryId) async {
    // 1. Update di RAM (agar UI langsung berubah)
    viewedStoryIds.add(uniqueStoryId);

    // 2. Simpan ke HP
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'viewed_stories_$currentUserId';

      // Simpan list yang sudah diupdate
      await prefs.setStringList(key, viewedStoryIds.toList());
    }
  }

  @override
  void onClose() {
    _storiesSubscription?.cancel();
    _refreshSubscription?.cancel();
    _logoutSubscription?.cancel();
    super.onClose();
  }

  void clearSession() {
    viewedStoryIds.clear(); // Kosongkan daftar yang sudah dilihat
    stories.clear();
    myStory.value = null;
  }
}
