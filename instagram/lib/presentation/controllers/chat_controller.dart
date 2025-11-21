import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/domain/entities/message.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/delete_message_usecase.dart';
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
  final DeleteMessageUseCase deleteMessageUseCase = locator<DeleteMessageUseCase>();

  // 2. Parameter (ID Lawan Bicara)
  final String otherUserId;

  // 3. State
  var isLoading = true.obs;
  var messages = <Message>[].obs;
  final Rx<UserEntity?> otherUser = Rx(null); // Data profil lawan bicara

  // 4. Input & Scroll
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final CloudinaryPublic cloudinary = locator<CloudinaryPublic>();

  final ImagePicker _picker = ImagePicker();
  var isUploading = false.obs;

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
  // --- FUNGSI PILIH & KIRIM MEDIA (VERSI AMAN) ---
  Future<void> pickAndSendMedia() async {
    // 1. Tentukan tipe DULU tanpa membuka picker langsung
    final bool? isVideo = await Get.dialog<bool>(
       AlertDialog(
         title: Text("Kirim Media"),
         content: Column(mainAxisSize: MainAxisSize.min, children: [
           ListTile(
             leading: Icon(Icons.image), 
             title: Text("Foto"), 
             onTap: () => Get.back(result: false) // false = image
           ),
           ListTile(
             leading: Icon(Icons.videocam), 
             title: Text("Video"), 
             onTap: () => Get.back(result: true) // true = video
           ),
         ]),
       )
    );
    
    // Jika user klik luar dialog (null), batalkan.
    if (isVideo == null) return;

    // 2. Beri jeda sedikit agar dialog benar-benar tertutup di engine Flutter Web
    await Future.delayed(Duration(milliseconds: 200));

    try {
      final XFile? file;
      final MessageType type;
      
      // 3. Baru buka Picker
      if (isVideo) {
        file = await _picker.pickVideo(source: ImageSource.gallery);
        type = MessageType.video;
      } else {
        file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
        type = MessageType.image;
      }

      if (file == null) return;

      // 4. Mulai Upload
      isUploading.value = true; // Pastikan ada variabel RxBool isUploading = false.obs;
      
      final bytes = await file.readAsBytes();
      
      // Upload ke Cloudinary
      final response = await cloudinary.uploadFile(
         CloudinaryFile.fromByteData(
           bytes.buffer.asByteData(), 
           identifier: 'chat_${DateTime.now().millisecondsSinceEpoch}',
           folder: 'chats',
           resourceType: isVideo ? CloudinaryResourceType.Video : CloudinaryResourceType.Image
         )
      );

      // 5. Kirim Pesan
      final currentUserId = firebaseAuth.currentUser?.uid;
      if (currentUserId == null) return;

      final newMessage = Message(
         id: '',
         senderId: currentUserId,
         receiverId: otherUserId,
         text: "", 
         timestamp: DateTime.now(),
         type: type,
         mediaUrl: response.secureUrl,
      );

      await sendMessageUseCase(SendMessageParams(newMessage));
      _scrollToBottom();

    } catch (e) {
      print("Error Upload Chat: $e");
      Get.snackbar("Error", "Gagal kirim media: $e");
    } finally {
      isUploading.value = false;
    }
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
  void deleteMessage(Message message) async {
    // Konfirmasi Dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text("Hapus Pesan?"),
        content: Text("Pesan ini akan dihapus untuk Anda dan orang lain."),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text("Batal")),
          TextButton(onPressed: () => Get.back(result: true), child: Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    final result = await deleteMessageUseCase(
      DeleteMessageParams(
        messageId: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
      )
    );

    result.fold(
      (failure) => Get.snackbar("Error", failure.message),
      (success) {
        // Tidak perlu refresh manual karena kita pakai Stream di listenToMessages
        Get.snackbar("Sukses", "Pesan dihapus");
      }
    );
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}