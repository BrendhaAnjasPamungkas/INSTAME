import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/get_notification_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/toggle_follow_usecase.dart';
import 'package:instagram/injection_container.dart';

class NotificationController extends GetxController {
  final GetNotificationsUseCase getNotificationsUseCase = locator<GetNotificationsUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final ToggleFollowUseCase toggleFollowUseCase = locator<ToggleFollowUseCase>();
  final FirebaseAuth auth = locator<FirebaseAuth>();

  var notifications = <NotificationEntity>[].obs;
  final Rx<UserEntity?> currentUser = Rx(null);
  
  // --- TAMBAHAN: Cache User untuk Data Live ---
  var userCache = <String, UserEntity>{}.obs; 
  // ------------------------------------------

  StreamSubscription? _updateSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchCurrentUser();

    _updateSubscription = EventBus.profileStream.listen((event) {
      fetchCurrentUser(); 
      // Opsional: Refresh user cache juga jika perlu
    });
  }

  void fetchNotifications() {
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      notifications.bindStream(getNotificationsUseCase.execute(uid).map((either) {
        return either.fold(
          (l) => [], 
          (r) {
            // --- SETIAP ADA NOTIFIKASI, AMBIL DATA USER TERBARU ---
            for (var notif in r) {
              _fetchUserIfNotCached(notif.fromUserId);
            }
            // -----------------------------------------------------
            return r;
          }
        );
      }));
    }
  }

  // --- FUNGSI FETCH USER CACHE ---
  void _fetchUserIfNotCached(String uid) async {
    // Jika sudah ada di cache, tidak perlu ambil lagi (kecuali mau force refresh)
    if (userCache.containsKey(uid)) return;

    final result = await getUserDataUseCase(GetUserDataParams(uid));
    result.fold(
      (l) => null,
      (user) {
        userCache[uid] = user; // Simpan ke cache (memicu Obx di UI)
      }
    );
  }
  // -------------------------------

  void fetchCurrentUser() async {
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final result = await getUserDataUseCase(GetUserDataParams(uid));
      result.fold((l) => null, (user) => currentUser.value = user);
    }
  }

  void toggleFollow(String targetUserId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || currentUser.value == null) return;

    // Optimistic Update
    final isFollowing = currentUser.value!.following.contains(targetUserId);
    List<String> newFollowing = List.from(currentUser.value!.following);

    if (isFollowing) {
      newFollowing.remove(targetUserId);
    } else {
      newFollowing.add(targetUserId);
    }
    
    currentUser.value = currentUser.value!.copyWith(following: newFollowing);

    final result = await toggleFollowUseCase(ToggleFollowParams(targetUserId, uid));
    
    result.fold(
      (failure) {
        fetchCurrentUser(); 
        Get.snackbar("Error", failure.message);
      },
      (success) {
        EventBus.fireProfileUpdate(ProfileUpdateEvent());
      }
    );
  }
  
  @override
  void onClose() {
    _updateSubscription?.cancel();
    super.onClose();
  }
}