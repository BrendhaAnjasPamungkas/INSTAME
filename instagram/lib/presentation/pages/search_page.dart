import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/search_controller.dart';
import 'package:instagram/presentation/pages/profile_page.dart';
import 'package:instagram/presentation/widgets/main_widget.dart';

class SearchPage extends StatelessWidget {
  SearchPage({Key? key}) : super(key: key);

  // Buat controller
  final UserSearchController controller = Get.put(
    UserSearchController(),
    tag: "searchController",
  );
  
  // Controller untuk text field
  final _searchQueryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Kita gunakan TextField dari widget 'W' Anda
        title: W.textField(
          controller: _searchQueryController,
          contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          fillColor: Colors.grey[800],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          hint: W.text(data: "Cari...", color: Colors.grey[400]),
          fontColor: Colors.white,
          onChanged: (query) {
            // Panggil controller setiap kali user mengetik
            controller.search(query!);
          },
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        // Jika hasil masih kosong (dan tidak sedang loading)
        if (controller.users.isEmpty) {
          if (_searchQueryController.text.isEmpty) {
            return Center(child: W.text(data: "Cari pengguna berdasarkan username."));
          } else {
            return Center(child: W.text(data: "Pengguna tidak ditemukan."));
          }
        }

        // Tampilkan hasil pencarian
        return ListView.builder(
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            
            return ListTile(
              // TODO: Ganti dengan foto profil (Base64 atau Cloudinary)
             leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: user.profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                          errorWidget: (context, url, error) => Icon(Icons.person, color: Colors.grey[600]),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
                        ),
                ),
              ),
              title: W.text(data: user.username, fontWeight: FontWeight.bold),
              subtitle: W.text(data: user.fullName, color: Colors.grey[400]),
              onTap: () {
                // Navigasi ke ProfilePage dengan 'uid'
                Get.to(() => ProfilePage(userId: user.uid,));
              },
            );
          },
        );
      }),
    );
  }
}