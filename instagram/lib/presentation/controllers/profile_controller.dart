import 'dart:async';

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
  final GetUserDataUseCase getUserDataUseCase;
  StreamSubscription? _userPostsSubscription;
  final GetUserPostsUseCase getUserPostsUseCase;
  final LogOutUseCase logOutUseCase;
  final FirebaseAuth firebaseAuth;
  final ToggleFollowUseCase toggleFollowUseCase;

  // ✅ PERBAIKAN: Hanya satu variabel untuk userId
  final String profileUserId;
  late StreamSubscription profileUpdateSubscription;

  ProfileController({required this.profileUserId})
    : getUserDataUseCase = locator<GetUserDataUseCase>(),
      getUserPostsUseCase = locator<GetUserPostsUseCase>(),
      logOutUseCase = locator<LogOutUseCase>(),
      firebaseAuth = locator<FirebaseAuth>(),
      toggleFollowUseCase = locator<ToggleFollowUseCase>();

  // State untuk UI
  var isLoading = true.obs;
  final Rx<UserEntity?> user = Rx(null);
  var posts = <Post>[].obs;
  final RxString profilePicUrl = "".obs;

  // Getter
  bool get isMyProfile => profileUserId == firebaseAuth.currentUser?.uid;
  bool get isFollowing =>
      user.value?.followers.contains(firebaseAuth.currentUser?.uid) ?? false;

  @override
  void onInit() {
    super.onInit();
    profileUpdateSubscription = EventBus.profileStream.listen((event) {
      // Jika ada event, panggil 'fetchProfileData' lagi
      fetchProfileData();
    });

    fetchProfileData();
  }

  void updateProfilePic(String newUrl) {
    profilePicUrl.value = newUrl;
    if (user.value != null) {
      user.value = user.value!.copyWith(profileImageUrl: newUrl);
    }
  }

  void fetchProfileData() async {
    isLoading.value = true;

    final currentAuthUser = firebaseAuth.currentUser;
    if (currentAuthUser == null) {
      isLoading.value = false;
      Get.offAll(() => LoginPage());
      return;
    }

    // ✅ 1. Ambil data user YANG BENAR (profileUserId, bukan currentUser.uid)
    final userDataResult = await getUserDataUseCase(
      GetUserDataParams(profileUserId),
    );

    userDataResult.fold(
      (failure) {
        Get.snackbar("Error Profil", failure.message);
      },
      (userEntity) {
        user.value = userEntity;
        profilePicUrl.value = userEntity.profileImageUrl ?? "";
      },
    );

    await _userPostsSubscription?.cancel(); 

    // Simpan stream baru ke variabel
    _userPostsSubscription = getUserPostsUseCase.execute(GetUserPostsParams(profileUserId)).listen((postsResult) {
      postsResult.fold(
        (failure) { /* ... */ },
        (postList) {
          posts.value = postList;
        }
      );
    });

    // ✅ 2. Ambil postingan YANG BENAR (profileUserId, bukan currentUser.uid)
    getUserPostsUseCase.execute(GetUserPostsParams(profileUserId)).listen((
      postsResult,
    ) {
      postsResult.fold(
        (failure) {
          // Biarkan grid kosong jika error
        },
        (postList) {
          posts.value = postList;
        },
      );
    });

    isLoading.value = false;
  }

  // ✅ PERBAIKAN: toggleFollow yang diperbaiki
  void toggleFollow() async {
    final currentUserId = firebaseAuth.currentUser?.uid;

    if (currentUserId == null || isMyProfile) {
      Get.snackbar("Error", "Tidak bisa follow diri sendiri.");
      return;
    }

    // ✅ Gunakan profileUserId langsung (bukan _profileUserId yang null)
    final result = await toggleFollowUseCase(
      ToggleFollowParams(
        targetUserId: profileUserId, // ← PERBAIKAN DI SINI
        currentUserId: currentUserId,
      ),
    );

    result.fold((failure) => Get.snackbar("Error", failure.message), (
      success,
    ) async {
      // Refresh data user agar tombol update
      final userDataResult = await getUserDataUseCase(
        GetUserDataParams(profileUserId),
      );
      userDataResult.fold((f) => null, (userEntity) {
        user.value = userEntity;
      });
    });
  }

  void logOut() async {
    final result = await logOutUseCase(NoParams());
    result.fold(
      (failure) => Get.snackbar("Error", failure.message),
      (success) {EventBus.fireLogout(LogoutEvent());
      Get.offAll(() => LoginPage());}
  );}

  @override
  void onClose() {
    // --- TAMBAHKAN INI ---
    profileUpdateSubscription.cancel(); // Hentikan langganan
    _userPostsSubscription?.cancel();
    // ---
    super.onClose();
  }
}
