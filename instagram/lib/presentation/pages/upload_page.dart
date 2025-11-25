import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/presentation/controllers/upload_controller.dart';
import 'package:instagram/presentation/widgets/upload_preiew_widget.dart'; // Pastikan nama file import benar (tadi ada typo 'preiew')

class UploadPage extends StatelessWidget {
  UploadPage({Key? key}) : super(key: key);

  final UploadController controller = Get.put(
    UploadController(),
    tag: "uploadController", 
  );

  final _captionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 1. Bungkus seluruh Scaffold dengan Obx agar bereaksi terhadap loading
    return Obx(() {
      final bool isLoading = controller.isLoading.value;

      // 2. PopScope: Mencegah tombol Back HP berfungsi saat loading
      return PopScope(
        canPop: !isLoading, 
        child: Scaffold(
          appBar: AppBar(
            title: Text("Buat Postingan Baru"),
            // 3. Kontrol Tombol Back di AppBar secara manual
            automaticallyImplyLeading: false, 
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              // Jika loading, tombol ini mati (null). Jika tidak, bisa back.
              onPressed: isLoading ? null : () => Get.back(),
            ),
            actions: [
              // Tombol Upload / Loading
              isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.check, color: Colors.blue),
                      onPressed: () {
                        controller.uploadPost(_captionController.text);
                      },
                    ),
            ],
          ),
          
          // 4. AbsorbPointer: Memblokir semua sentuhan di body saat loading
          body: AbsorbPointer(
            absorbing: isLoading, // Jika true, layar beku (tidak bisa diklik)
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Area Pilihan Gambar
                  Obx(() {
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
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            height: 300,
                            width: double.infinity,
                            color: Colors.black,
                            child: UploadPreviewWidget(
                              file: controller.selectedImage.value!,
                              type: controller.selectedType,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                            onPressed: () {
                              controller.selectedImage.value = null;
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
          ),
        ),
      );
    });
  }
}