import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/domain/entities/message.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/get_message_usecase.dart';
import 'package:instagram/domain/usecase/get_user_data_usecase.dart';
import 'package:instagram/domain/usecase/send_message_usecase.dart';
import 'package:instagram/injection_container.dart';

class ChatController extends GetxController {
  // 1. Dependensi (Locator)
  final SendMessageUseCase sendMessageUseCase = locator<SendMessageUseCase>();
  final GetMessagesUseCase getMessagesUseCase = locator<GetMessagesUseCase>();
  final GetUserDataUseCase getUserDataUseCase = locator<GetUserDataUseCase>();
  final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();

  // 2. Parameter (ID Lawan Bicara)
  final String otherUserId;

  // 3. State
  var isLoading = true.obs;
  var messages = <Message>[].obs;
  final Rx<UserEntity?> otherUser = Rx(null); // Data profil lawan bicara

  // 4. Input & Scroll
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  ChatController({required this.otherUserId});

  @override
  void onInit() {
    super.onInit();
    fetchOtherUserProfile();
    listenToMessages();
  }

  // Ambil data profil lawan bicara (untuk nama & foto di AppBar)
  void fetchOtherUserProfile() async {
    final result = await getUserDataUseCase(GetUserDataParams(otherUserId));
    result.fold(
      (l) => null,
      (user) => otherUser.value = user,
    );
  }

  // Dengarkan pesan masuk real-time
  void listenToMessages() {
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return;

    isLoading.value = true;

    // Bind Stream ke variabel messages
    messages.bindStream(
      getMessagesUseCase.execute(
        GetMessagesParams(otherUserId: otherUserId, currentUserId: currentUserId)
      ).map((either) {
        return either.fold(
          (failure) => [], // Jika error, kembalikan list kosong
          (msgs) {
            // Scroll ke bawah setiap ada pesan baru (setelah delay dikit biar render dulu)
            Future.delayed(Duration(milliseconds: 100), () => _scrollToBottom());
            return msgs;
          }
        );
      })
    );
    
    isLoading.value = false;
  }

  void sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return;

    textController.clear(); // Langsung bersihkan input biar responsif

    final newMessage = Message(
      id: '', // Firestore akan generate
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text,
      timestamp: DateTime.now(),
    );

    final result = await sendMessageUseCase(SendMessageParams(newMessage));

    result.fold(
      (failure) => Get.snackbar("Error", "Gagal mengirim pesan"),
      (success) => _scrollToBottom(),
    );
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}