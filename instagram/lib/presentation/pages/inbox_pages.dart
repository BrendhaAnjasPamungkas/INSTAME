import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/presentation/controllers/inbox_controller.dart';
import 'package:instagram/presentation/pages/chat_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class InboxPage extends StatelessWidget {
  InboxPage({Key? key}) : super(key: key);

  final InboxController controller = Get.put(InboxController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: W.text(data: "Chats", fontWeight: FontWeight.bold),
      ),
      body: Obx(() {
        // 1. Loading Awal
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        // 2. Kosong
        if (controller.chatRooms.isEmpty) {
          return Center(child: W.text(data: "Belum ada pesan."));
        }

        // 3. List Chat Rooms
        return ListView.builder(
          itemCount: controller.chatRooms.length,
          itemBuilder: (context, index) {
            final room = controller.chatRooms[index];
            
            // --- PERBAIKAN DI SINI: Obx BERSARANG ---
            // Kita bungkus ListTile (atau bagian isinya) dengan Obx
            // agar dia "menunggu" data user masuk ke userCache map.
            return Obx(() {
              final UserEntity? otherUser = controller.userCache[room.otherUserId];
              
              // Data Tampilan Default (Loading)
              String displayUsername = "Loading...";
              ImageProvider? displayImage;

              // Jika data user sudah ada di cache
              if (otherUser != null) {
                displayUsername = otherUser.username;
                if (otherUser.profileImageUrl != null && otherUser.profileImageUrl!.isNotEmpty) {
                  displayImage = CachedNetworkImageProvider(otherUser.profileImageUrl!);
                }
              }

              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: displayImage,
                  child: (displayImage == null) 
                      ? Icon(Icons.person, color: Colors.grey[400]) 
                      : null,
                ),
                title: W.text(
                  data: displayUsername, // <-- Akan berubah otomatis
                  fontWeight: FontWeight.bold,
                ),
                subtitle: W.text(
                  data: room.lastMessage,
                  color: Colors.grey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // Buka Chat Room
                  Get.to(() => ChatPage(otherUserId: room.otherUserId));
                },
              );
            });
            // --------------------------------------
          },
        );
      }),
    );
  }
}