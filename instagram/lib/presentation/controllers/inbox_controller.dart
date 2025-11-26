import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/domain/entities/chat_room.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/get_chat_rooms_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/mark_chat_read_usecase.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/pages/chat_page.dart';

class InboxController extends GetxController {
  final GetChatRoomsUseCase getChatRoomsUseCase = locator<GetChatRoomsUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
  final MarkChatReadUseCase markChatReadUseCase = locator<MarkChatReadUseCase>(); // Inject

  var isLoading = true.obs;
  var chatRooms = <ChatRoom>[].obs;
  var hasUnreadMessages = false.obs;
  
  // Cache data user (RxMap agar reaktif)
  var userCache = <String, UserEntity>{}.obs; 

  @override
  void onInit() {
    super.onInit();
    fetchInbox();
  }

  void fetchInbox() {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    isLoading.value = true;

    chatRooms.bindStream(
      getChatRoomsUseCase.execute(GetChatRoomsParams(uid)).map((either) {
        return either.fold(
          (failure) => [],
          (rooms) {
            // --- LOGIKA BADGE ---
            if (rooms.isNotEmpty) {
               // Idealnya cek field 'unreadCount' di database
               // Sementara kita nyalakan jika ada chat room
               hasUnreadMessages.value = true;
            }
            // --------------------

            for (var room in rooms) {
              _fetchUserIfNotCached(room.otherUserId);
            }
            isLoading.value = false;
            return rooms;
          }
        );
      })
    );
  }
  void markAsRead() {
    hasUnreadMessages.value = false;
  }

  void _fetchUserIfNotCached(String uid) async {
    if (userCache.containsKey(uid)) return; // Sudah ada, skip

    print("INBOX: Fetching user info for $uid...");
    
    final result = await getUserDataUseCase(GetUserDataParams(uid));
    result.fold(
      (l) => print("INBOX: Gagal fetch user $uid"),
      (user) {
        print("INBOX: Sukses fetch user ${user.username}");
        // Simpan ke cache (ini akan memicu Obx yang mendengarkan userCache)
        userCache[uid] = user; 
      }
    );
  }
  void openChat(String chatRoomId, String otherUserId) {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid != null) {
      // Tandai sudah dibaca di database
      markChatReadUseCase(MarkChatReadParams(chatRoomId, uid));
    }
    // Buka Chat Page
    Get.to(() => ChatPage(otherUserId: otherUserId));
  }
}