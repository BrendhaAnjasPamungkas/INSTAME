import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/upload_controller.dart';
import 'package:instagram/presentation/widgets/upload_preiew_widget.dart';

class UploadPage extends StatelessWidget {
  UploadPage({Key? key}) : super(key: key);

  // Buat controller menggunakan Get.put() & inject dependencies
  final UploadController controller = Get.put(
    UploadController(),
    tag: "uploadController", // Beri tag unik
  );

  // Controller untuk text field caption
  final _captionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buat Postingan Baru"),
        actions: [
          // Tombol "Upload"
          Obx(
            () => controller.isLoading.value
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.check, color: Colors.blue),
                    onPressed: () {
                      controller.uploadPost(_captionController.text);
                    },
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Area Pilihan Gambar
            Obx(() {
              // Jika gambar belum dipilih
              if (controller.selectedImage.value == null) {
                return GestureDetector(
                  onTap: () {
                    controller.pickImage();
                  },
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[800],
                    child: Center(
                      child: Icon(Icons.add_a_photo_outlined, size: 50),
                    ),
                  ),
                );
              } else {
                // Jika gambar sudah dipilih
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.black,
                      child: UploadPreviewWidget(
                        file: controller.selectedImage.value!, // Kirim XFile
                        type: controller.selectedType,         // Kirim PostType
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                      onPressed: () {
                        controller.selectedImage.value = null; // Hapus pilihan
                      },
                    ),
                  ],
                );
              }
            }),

            SizedBox(height: 16),

            // Text Field untuk Caption
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: "Tulis caption...",
                border: InputBorder.none,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
  
}
