import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/presentation/controllers/edit_profile_controller.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class EditProfilePage extends StatelessWidget {
  final UserEntity currentUser;

  const EditProfilePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan Get.lazyPut() untuk controller agar hanya diinisialisasi sekali
    final EditProfileController controller = Get.put(EditProfileController(currentUser: currentUser));

    return Scaffold(
      appBar: AppBar(
        title: W.text(data: "Edit Profil"),
        actions: [
          Obx(() => controller.isLoading.value
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              : IconButton(
                  icon: Icon(Icons.check, color: Colors.blue),
                  onPressed: () {
                    controller.saveProfile();
                  },
                )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(onTap: () => controller.pickImage(),child: Obx(() {
              ImageProvider? backgroundImage;
              if (controller.selectedImage.value != null) {
                  // Tampilkan preview lokal (Untuk Web, path adalah blob URL)
                  backgroundImage = NetworkImage(controller.selectedImage.value!.path);
                } else if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
                  // Tampilkan foto lama dari internet
                  backgroundImage = CachedNetworkImageProvider(currentUser.profileImageUrl!);
                }

                return CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: backgroundImage,
                  child: (backgroundImage == null)
                      ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                      : null,
                );

            },),),
            W.gap(height: 8),
            W.text(data: "Ganti foto profil", color: Colors.blue),
            W.gap(height: 24),
            W.textField(
              controller: controller.usernameController,
              label: W.text(data: "Username"),
              fontColor: Colors.white,
              fillColor: Colors.grey[800],
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            W.gap(height: 16),
            W.textField(
              controller: controller.bioController,
              label: W.text(data: "Bio"),
              maxLines: 4,
              fontColor: Colors.white,
              fillColor: Colors.grey[800],
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ],
        ),
      ),
    );
  }
}
