import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/presentation/controllers/notification_controller.dart';
import 'package:instagram/presentation/pages/commen2_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class ActivityPage extends StatelessWidget {
  final controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: W.text(data: "Notifikasi", fontWeight: FontWeight.bold),
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: W.text(data: "Belum ada notifikasi.", color: Colors.white),
          );
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];

            return ListTile(
              leading: ClipOval(
                child: Container(
                  width: 40, // Ukuran standar avatar di ListTile
                  height: 40,
                  color: Colors.grey[800], // Warna background dasar
                  child:
                      (notif.fromUserProfileUrl != null &&
                          notif.fromUserProfileUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: notif.fromUserProfileUrl!,
                          fit: BoxFit.cover,
                          // Tampilkan container kosong saat loading
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[800]),
                          // Tampilkan Icon Person jika URL error/gambar tidak ditemukan
                          errorWidget: (context, url, error) =>
                              Icon(Icons.person, color: Colors.white),
                        )
                      // Tampilkan Icon Person jika URL memang kosong/null dari database
                      : Icon(Icons.person, color: Colors.white),
                ),
              ),

              title: W.richText(
                children: [
                  W.textSpan(
                    text: "${notif.fromUsername} ",
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  W.textSpan(text: _getNotifText(notif), color: Colors.white),
                ],
              ),
              subtitle: W.text(
                data: _getTimeAgo(notif.timestamp),
                color: Colors.grey,
              ),
              trailing: _getTrailingWidget(notif),
              onTap: () {
                // 1. JIKA NOTIFIKASI KOMENTAR -> Ke CommentsPage
                if (notif.type == NotificationType.comment) {
                  if (notif.postId != null) {
                    Get.to(() => CommentsPage(postId: notif.postId!));
                  }
                }
                // 2. JIKA NOTIFIKASI LIKE -> Ke PostDetailPage (FEED)
                else if (notif.type == NotificationType.like) {
                  if (notif.postId != null) {
                    // SEMENTARA: Tampilkan snackbar
                    Get.snackbar("Info", "Buka postingan ID: ${notif.postId}");

                    // NANTI: Kita akan implementasi GetPostByIdUseCase
                    // Get.to(() => PostDetailPage(postId: notif.postId!));
                  }
                }
              },
            );
          },
        );
      }),
    );
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

  Widget? _getTrailingWidget(NotificationEntity notif) {
    if (notif.type == NotificationType.follow) {
      return W.button(
        onPressed: () {},
        child: W.text(data: "Follow", color: Colors.white),

        padding: EdgeInsets.symmetric(horizontal: 16),
      );
    }
    if (notif.postImageUrl != null) {
      return Container(
        width: 40,
        height: 40,
        child: CachedNetworkImage(
          imageUrl: notif.postImageUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
    return null;
  }
}

// --- FUNGSI HELPER WAKTU ---
String _getTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return "${diff.inDays}h"; // Hari
  if (diff.inHours > 0) return "${diff.inHours}j"; // Jam
  if (diff.inMinutes > 0) return "${diff.inMinutes}m"; // Menit
  return "Baru saja";
}
