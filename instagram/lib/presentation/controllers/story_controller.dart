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
  // ignore: unused_field
  StreamSubscription? _profileUpdateSubscription;

  @override
  void onInit() {
    super.onInit();
    
    firebaseAuth.authStateChanges().listen((user) {
      if (user != null) fetchStories();
    });

    _refreshSubscription = EventBus.feedStream.listen((event) {
      fetchStories();
    });

    // --- REAKTIVITAS UPDATE PROFIL ---
    // Saat Edit Profil selesai, ambil ulang data user agar foto baru terambil
    _profileUpdateSubscription = EventBus.profileStream.listen((event) {
      print("STORY: Profil berubah. Mengambil data user baru...");
      fetchStories(); 
    });
    // ---------------------------------

    _logoutSubscription = EventBus.logoutStream.listen((event) {
      stories.clear();
      myStory.value = null;
      viewedStoryIds.clear();
      currentUserProfilePic.value = "";
    });
  }

void fetchStories() async {
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return; 

    try {
      await _loadViewedStatusFromLocal(currentUserId);
    } catch (e) {
      // Abaikan error prefs
    }

    // 1. Ambil Data User (Termasuk Foto Profil Terbaru)
    final userDataResult = await getUserDataUseCase(GetUserDataParams(currentUserId));
    
    userDataResult.fold(
      (failure) {},
      (user) {
        // --- UPDATE STATE FOTO PROFIL ---
        // Ini yang bikin Feed & Story Button berubah otomatis!
        currentUserProfilePic.value = user.profileImageUrl ?? "";
        // --------------------------------
        
        final List<String> allIdsToCheck = List.from(user.following);
        allIdsToCheck.add(user.uid); 

        _storiesSubscription?.cancel();

        _storiesSubscription = getStoriesUseCase.execute(GetStoriesParams(followingIds: allIdsToCheck))
          .listen((eitherResult) {
            isLoading.value = false; 
            eitherResult.fold(
              (failure) {},
              (allStories) {
                final myStoryIndex = allStories.indexWhere((s) => s.id == currentUserId);
                if (myStoryIndex != -1) {
                  myStory.value = allStories[myStoryIndex];
                  allStories.removeAt(myStoryIndex);
                } else {
                  myStory.value = null;
                }
                stories.value = allStories;
              },
            );
          }, onError: (e) => isLoading.value = false);
      }
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
