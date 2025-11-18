import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/controllers/chat_controller.dart';
import 'package:instagram/presentation/widgets/chat_bubblw.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class ChatPage extends StatelessWidget {
  final String otherUserId;

  const ChatPage({Key? key, required this.otherUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Buat controller dengan TAG unik (ID user lawan) 
    // supaya bisa chat dengan banyak orang berbeda tanpa bentrok
    final ChatController controller = Get.put(
      ChatController(otherUserId: otherUserId),
      tag: "chat_$otherUserId",
    );

    final currentUserId = locator<FirebaseAuth>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Obx(() {
          final user = controller.otherUser.value;
          if (user == null) return W.text(data: "Loading...");

          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                backgroundImage: (user.profileImageUrl != null)
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: (user.profileImageUrl == null) 
                    ? Icon(Icons.person, size: 20) : null,
              ),
              W.gap(width: 10),
              W.text(
                data: user.username, 
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ],
          );
        }),
      ),
      body: Column(
        children: [
          // 1. LIST PESAN
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: W.text(data: "Mulai percakapan 👋", color: Colors.grey),
                );
              }
              
              return ListView.builder(
                controller: controller.scrollController,
                itemCount: controller.messages.length,
                padding: EdgeInsets.only(bottom: 10, top: 10),
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  final bool isMe = msg.senderId == currentUserId;

                  return ChatBubble(
                    text: msg.text,
                    isMe: isMe,
                  );
                },
              );
            }),
          ),

          // 2. INPUT TEXT
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Colors.grey[900]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField( // Gunakan TextField biasa agar lebih fleksibel di row
                      controller: controller.textController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Kirim pesan...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                W.gap(width: 8),
                // Tombol Kirim
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () => controller.sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}