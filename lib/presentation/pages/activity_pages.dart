import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/presentation/controllers/notification_controller.dart';
import 'package:instagram/presentation/pages/comments_page.dart';
import 'package:instagram/presentation/pages/post_detail_page.dart';
import 'package:instagram/presentation/pages/profile_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
// --- IMPORT UNIVERSAL IMAGE ---
import 'package:instagram/presentation/widgets/universal_image.dart';

class ActivityPage extends StatelessWidget {
  // Gunakan Get.put agar controller dibuat
  final NotificationController controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: W.text(data: "Notifikasi", fontWeight: FontWeight.bold),
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(child: W.text(data: "Belum ada notifikasi."));
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];

            // --- INI PERBAIKANNYA (DATA LIVE) ---
            // Kita bungkus ListTile dengan Obx (atau bagian yg butuh data live)
            return Obx(() {
              // Cek apakah ada data user terbaru di cache?
              final UserEntity? liveUser =
                  controller.userCache[notif.fromUserId];

              // Prioritaskan data live, kalau belum ada pakai data snapshot notif
              final String displayPicUrl =
                  liveUser?.profileImageUrl ?? notif.fromUserProfileUrl ?? "";
              final String displayUsername =
                  liveUser?.username ?? notif.fromUsername;

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[800],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: UniversalImage(
                      imageUrl: displayPicUrl, // <-- GUNAKAN URL LIVE
                      width: 40,
                      height: 40,
                      isCircle: true,
                    ),
                  ),
                ),
                title: W.richText(
                  children: [
                    W.textSpan(
                      text: "$displayUsername ",
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ), // <-- GUNAKAN USERNAME LIVE
                    W.textSpan(text: _getNotifText(notif), color: Colors.white),
                  ],
                ),
                subtitle: W.text(
                  data: _getTimeAgo(notif.timestamp),
                  color: Colors.grey,
                ),

                trailing: _buildTrailingWidget(notif),

                onTap: () {
                  if (notif.type == NotificationType.comment) {
                    if (notif.postId != null)
                      Get.to(() => CommentsPage(postId: notif.postId!));
                  } else if (notif.type == NotificationType.like) {
                    if (notif.postId != null) {
                      Get.to(() => PostDetailPage(postId: notif.postId!));
                    }
                  } else if (notif.type == NotificationType.follow) {
                    Get.to(() => ProfilePage(userId: notif.fromUserId));
                  }
                },
              );
            });
          },
        );
      }),
    );
  }

  // --- LOGIKA TOMBOL FOLLOW CERDAS ---
  Widget? _buildTrailingWidget(NotificationEntity notif) {
    if (notif.type == NotificationType.follow) {
      // Bungkus dengan Obx agar tombol berubah real-time
      return Obx(() {
        final currentUser = controller.currentUser.value;
        if (currentUser == null) return SizedBox.shrink(); // Loading state

        // Cek apakah kita sudah follow dia
        final isFollowing = currentUser.following.contains(notif.fromUserId);

        return SizedBox(
          width: 120, // Batasi lebar agar rapi
          height: 35,
          child: W.button(
            onPressed: () {
              controller.toggleFollow(notif.fromUserId);
            },
            // Ubah teks dan warna berdasarkan status
            child: W.text(
              data: isFollowing ? "Following" : "Follow Back",
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
          ),
        );
      });
    }

    // --- 2. GANTI PREVIEW POSTINGAN DENGAN UNIVERSAL IMAGE ---
    if (notif.postImageUrl != null) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
           border: Border.all(color: Colors.grey[800]!),
           borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Tampilkan Thumbnail (Bukan Video Asli)
            UniversalImage(
              imageUrl: _getThumbnailUrl(notif.postImageUrl!), // Gunakan helper
              fit: BoxFit.cover,
            ),
            
            // 2. Ikon Play Kecil (Jika aslinya video)
            if (notif.postImageUrl!.endsWith('.mp4'))
              Center(
                child: Icon(Icons.play_arrow, size: 20, color: Colors.white),
              ),
          ],
        ),
      );
    }
    // ---------------------------------------------------------
    return null;
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}h";
    if (diff.inHours > 0) return "${diff.inHours}j";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Baru saja";
  }

  String _getNotifText(NotificationEntity notif) {
    switch (notif.type) {
      case NotificationType.like:
        return "menyukai postingan anda.";
      case NotificationType.comment:
        return "mengomentari: ${notif.text}";
      case NotificationType.follow:
        return "mulai mengikuti anda.";
    }
  }
  String _getThumbnailUrl(String url) {
    if (url.endsWith('.mp4')) {
      return url.replaceAll('.mp4', '.jpg');
    }
    return url;
  }
}
