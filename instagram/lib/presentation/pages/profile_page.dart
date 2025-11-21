import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/injection_container.dart';
import 'package:instagram/presentation/controllers/profile_controller.dart';
import 'package:instagram/presentation/pages/chat_page.dart';
import 'package:instagram/presentation/pages/edit_profile_page.dart';
import 'package:instagram/presentation/pages/post_detail_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class ProfilePage extends StatelessWidget {
  final String? userId;

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userIdToUse =
        userId ?? locator<FirebaseAuth>().currentUser!.uid;
    final String tag = userIdToUse;

    // --- PERBAIKAN: Hapus Get.lazyPut dan Get.find ---
    // Gunakan Get.put langsung. Ini akan membuat controller baru jika belum ada,
    // atau mengembalikan yang sudah ada berdasarkan 'tag'.
    final ProfileController controller = Get.put(
      ProfileController(profileUserId: userIdToUse),
      tag: tag,
    );
    // ------------------------------------------------

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
          // Karena controller sudah ada, kita bisa akses langsung tanpa Get.find
          controller.isMyProfile
              ? IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () => controller.logOut(),
                )
              : SizedBox.shrink(),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        if (controller.user.value == null) {
          return Center(child: W.text(data: "Gagal memuat profil."));
        }

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: _buildProfileHeader(controller)),
              SliverToBoxAdapter(child: _buildActionButtons(controller)),
            ];
          },
          body: _buildProfileGrid(controller),
        );
      }),
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    final user = controller.user.value;

    if (user == null) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      child: (url.isNotEmpty)
                          ? CachedNetworkImage(
                              key: ValueKey(
                                controller.user.value!.profileImageUrl!,
                              ),

                              imageUrl: user.profileImageUrl!,
                              useOldImageOnUrlChange: true,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[900]),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.person, color: Colors.grey[600]),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      // ignore: invalid_use_of_protected_member
                      controller.posts.value.length,
                      "Postingan",
                    ),
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
    // Kita gunakan Obx di sini agar tombol berubah (Follow/Unfollow)
    // jika status isFollowing berubah

    if (controller.isMyProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: W.button(
          onPressed: () async {
            print("DEBUG: Membuka halaman Edit Profil...");

            final result = await Get.to(
              () => EditProfilePage(currentUser: controller.user.value!),
            );

            print("DEBUG: Kembali di ProfilePage. Data diterima: $result");

            if (result != null && result is UserEntity) {
              print("DEBUG: Data valid. Mengupdate state sekarang...");
              controller.user.value = result;
              controller.user.refresh();
              print("DEBUG: State berhasil di-refresh.");
            } else {
              print("DEBUG: Data null atau format salah.");
            }
          },
          child: W.text(data: "Edit Profil"),
        ),
      );
   } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row( // Gunakan Row untuk mensejajarkan tombol
          children: [
            // Tombol Follow (Existing)
            Expanded(
              child: W.button(
                onPressed: () {
                  controller.toggleFollow();
                },
                child: W.text(data: controller.isFollowing ? "Unfollow" : "Follow"),
                backgroundColor: controller.isFollowing ? Colors.grey[800] : Colors.blue,
              ),
            ),
            
            W.gap(width: 8),
            
            // --- TOMBOL MESSAGE BARU ---
            Expanded(
              child: W.button(
                onPressed: () {
                  // Navigasi ke ChatPage
                  // Kita butuh ID user ini (yang ada di controller.profileUserId)
                  Get.to(() => ChatPage(otherUserId: controller.profileUserId));
                },
                child: W.text(data: "Message"),
                backgroundColor: Colors.grey[800],
              ),
            ),
            // ---------------------------
          ],
        ),
      );
    }}
  Widget _buildProfileGrid(ProfileController controller) {
    // ignore: invalid_use_of_protected_member
    final List<Post> posts = controller.posts.value;

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

        // --- LOGIKA VIDEO vs GAMBAR ---
        return GestureDetector(
          onTap: () {
            // Navigasi ke Post Detail
           Get.to(() => PostDetailPage(
              posts: controller.posts.value, // Kirim list
              initialIndex: index,           // Kirim posisi klik
            ));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar Postingan
              CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              
              // (Opsional tapi Bagus) Ikon Play jika itu Video
              if (post.type == PostType.video)
                Center(
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
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
}
