import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/controllers/feed_controller.dart';
import 'package:instagram/presentation/controllers/profile_controller.dart';
import 'package:instagram/presentation/controllers/story_controller.dart';
import 'package:instagram/presentation/pages/chat_page.dart';
import 'package:instagram/presentation/pages/edit_profile_page.dart';
import 'package:instagram/presentation/pages/post_detail_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';
import 'package:instagram/presentation/widgets/universal_image.dart'; // Gunakan UniversalImage

class ProfilePage extends StatelessWidget {
  final String? userId;

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userIdToUse =
        userId ?? locator<FirebaseAuth>().currentUser!.uid;
    final String tag = userIdToUse;

    // 1. Inisialisasi ProfileController Utama
    final ProfileController controller = Get.put(
      ProfileController(profileUserId: userIdToUse),
      tag: tag,
    );

    // 2. Inisialisasi Controller Pendukung (Tanpa Get.find di child widget)
    final FeedController feedController = Get.put(
      FeedController(),
      tag: "feedController",
    );

    final StoryController storyController = Get.put(
      StoryController(),
      tag: "storyController",
    );

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => W.text(
            data: controller.user.value?.username ?? "Profil",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Hapus Obx di sini karena isMyProfile bukan Rx
          if (controller.isMyProfile)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => controller.logOut(),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value;
        if (user == null) {
          return Center(child: W.text(data: "Gagal memuat profil."));
        }

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildProfileHeader(controller, storyController),
              ),
              SliverToBoxAdapter(child: _buildActionButtons(controller)),
            ];
          },
          // Kirim controller ke Grid
          body: _buildProfileGrid(controller, feedController, storyController),
        );
      }),
    );
  }

  Widget _buildProfileHeader(
    ProfileController controller,
    StoryController storyController,
  ) {
    final user = controller.user.value!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // FOTO PROFIL (Mendengarkan ProfileController untuk URL)
              Obx(() {
                final String url = controller.profilePicUrl.value;
                return Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ClipOval(
                      child: UniversalImage(
                        imageUrl: url,
                        width: 86,
                        height: 86,
                        isCircle: true,
                      ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(controller.posts.length, "Postingan"),
                    _buildStatColumn(user.followers.length, "Followers"),
                    _buildStatColumn(user.following.length, "Following"),
                  ],
                ),
              ),
            ],
          ),
          W.gap(height: 12),
          W.text(
            data: user.fullName,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          W.gap(height: 4),
          W.text(data: user.bio ?? "", fontSize: 14),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ProfileController controller) {
    // Tombol Edit Profil (Milik Sendiri)
    if (controller.isMyProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: W.button(
          onPressed: () async {
            // Kirim data user saat ini ke halaman edit
            final result = await Get.to(
              () => EditProfilePage(currentUser: controller.user.value!),
            );

            // Update state manual jika ada kembalian data baru
            if (result != null && result is UserEntity) {
              controller.user.value = result;
              controller.profilePicUrl.value = result.profileImageUrl ?? "";
            }
          },
          child: W.text(data: "Edit Profil"),
        ),
      );
    }
    // Tombol Follow/Message (Orang Lain)
    else {
      return Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: W.button(
                  onPressed: () => controller.toggleFollow(),
                  child: W.text(
                    data: controller.isFollowing ? "Unfollow" : "Follow",
                  ),
                  backgroundColor: controller.isFollowing
                      ? Colors.grey[800]
                      : Colors.blue,
                ),
              ),
              W.gap(width: 8),
              Expanded(
                child: W.button(
                  onPressed: () => Get.to(
                    () => ChatPage(otherUserId: controller.profileUserId),
                  ),
                  child: W.text(data: "Message"),
                  backgroundColor: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildProfileGrid(
    ProfileController controller,
    FeedController feedController,
    StoryController storyController,
  ) {
    final List<Post> posts = controller.posts;

    if (posts.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          heightFactor: 5,
          child: W.text(data: "Belum ada postingan."),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return GestureDetector(
          onTap: () {
            Get.to(
              () => PostDetailPage(
                posts: controller.posts,
                initialIndex: index,
                feedController: feedController,
                storyController: storyController,
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- PERBAIKAN: GUNAKAN THUMBNAIL ---
              UniversalImage(
                // Jika tipe video, kita ambil versi .jpg nya dari Cloudinary
                imageUrl: post.type == PostType.video
                    ? _getThumbnailUrl(post.imageUrl)
                    : post.imageUrl,
                fit: BoxFit.cover,
              ),
              // ------------------------------------

              // Ikon Play tetap ada di atas thumbnail agar user tahu itu video
              if (post.type == PostType.video)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Column _buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        W.text(
          data: num.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        W.gap(height: 4),
        W.text(
          data: label,
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
      ],
    );
  }

  // Fungsi untuk mengubah URL Video menjadi URL Thumbnail Gambar
  String _getThumbnailUrl(String url) {
    if (url.endsWith('.mp4')) {
      // Ganti akhiran .mp4 menjadi .jpg
      return url.replaceAll('.mp4', '.jpg');
    }
    return url; // Jika bukan mp4, kembalikan aslinya
  }
}
