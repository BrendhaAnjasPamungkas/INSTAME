import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/get_user_post_usecase.dart';
import 'package:instagram/domain/usecase/logout_usecase.dart';
import 'package:instagram/domain/usecase/toggle_follow_usecase.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/pages/login_page.dart';

class ProfileController extends GetxController {
  // Dependensi
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final GetUserPostsUseCase getUserPostsUseCase = locator<GetUserPostsUseCase>();
  final LogOutUseCase logOutUseCase = locator<LogOutUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  final ToggleFollowUseCase toggleFollowUseCase = locator<ToggleFollowUseCase>();

  final String profileUserId;
  
  // Subscription
  StreamSubscription? _profileUpdateSubscription;
  StreamSubscription? _userPostsSubscription;

  ProfileController({required this.profileUserId});

  // State
  var isLoading = true.obs;
  final Rx<UserEntity?> user = Rx(null);
  var posts = <Post>[].obs;
  final RxString profilePicUrl = "".obs;

  bool get isMyProfile => profileUserId == firebaseAuth.currentUser?.uid;
  bool get isFollowing => user.value?.followers.contains(firebaseAuth.currentUser?.uid) ?? false;

  @override
  void onInit() {
    super.onInit();
    
    // Listener Update Profil (Edit Profil)
    _profileUpdateSubscription = EventBus.profileStream.listen((event) {
      fetchProfileData();
    });

    fetchProfileData();
  }

  void fetchProfileData() async {
    print("PROFIL: Memulai fetchProfileData untuk ID: $profileUserId"); // <-- LOG 1
    
    if (user.value == null) isLoading.value = true;

    final currentAuthUser = firebaseAuth.currentUser;
    if (currentAuthUser == null) {
      print("PROFIL: Gagal, user belum login."); // <-- LOG 2
      isLoading.value = false;
      Get.offAll(() => LoginPage());
      return;
    }

    // 1. Ambil Data User
    print("PROFIL: Mengambil data user..."); // <-- LOG 3
    final userDataResult = await getUserDataUseCase(GetUserDataParams(profileUserId));

    userDataResult.fold(
      (failure) {
        print("PROFIL: Gagal ambil user -> ${failure.message}"); // <-- LOG ERROR
        Get.snackbar("Error Profil", failure.message);
      },
      (userEntity) {
        print("PROFIL: Sukses ambil user: ${userEntity.username}"); // <-- LOG SUKSES
        user.value = userEntity;
        profilePicUrl.value = userEntity.profileImageUrl ?? "";
        
        // 2. Ambil Postingan
        print("PROFIL: Mengambil postingan..."); // <-- LOG 4
        _userPostsSubscription?.cancel();
        
        _userPostsSubscription = getUserPostsUseCase
            .execute(GetUserPostsParams(profileUserId))
            .listen((postsResult) {
              postsResult.fold(
                (failure) => print("PROFIL: Gagal stream post: ${failure.message}"),
                (postList) {
                  print("PROFIL: Dapat ${postList.length} postingan."); // <-- LOG POST
                  posts.value = postList;
                },
              );
            });
      },
    );

    isLoading.value = false;
  }
// ...

  void toggleFollow() async {
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null || isMyProfile) return;

    // 1. OPTIMISTIC UPDATE (Agar tidak stuck/loading)
    final currentUserData = user.value!;
    final isFollowed = isFollowing;
    List<String> newFollowers = List.from(currentUserData.followers);
    
    if (isFollowed) {
      newFollowers.remove(currentUserId);
    } else {
      newFollowers.add(currentUserId);
    }

    // Update UI Seketika
    user.value = currentUserData.copyWith(followers: newFollowers);

    // 2. PANGGIL API
   final result = await toggleFollowUseCase(
      // Panggil tanpa nama (karena sekarang positional)
      ToggleFollowParams(profileUserId, currentUserId), 
    );

    result.fold(
      (failure) {
         // Gagal? Kembalikan UI (Rollback)
         fetchProfileData(); 
         Get.snackbar("Error", failure.message);
      }, 
      (success) {
        // Sukses? 
        // Beri tahu NotificationController agar tombol di ActivityPage juga berubah
        EventBus.fireProfileUpdate(ProfileUpdateEvent());
        
        // Fetch ulang data untuk memastikan sinkron (opsional tapi aman)
        // fetchProfileData(); 
      }
    );
  }

  void logOut() {
    Get.dialog(
      AlertDialog(
        title: Text("Log Out"),
        content: Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Get.back(); 
              await logOutUseCase(NoParams());
              EventBus.fireLogout(LogoutEvent());
              Get.offAll(() => LoginPage());
              Get.snackbar("Sukses", "Berhasil Log out!");
            },
            child: Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _profileUpdateSubscription?.cancel();
    _userPostsSubscription?.cancel();
    super.onClose();
  }
}