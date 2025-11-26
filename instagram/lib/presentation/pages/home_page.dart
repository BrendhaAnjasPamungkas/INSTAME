import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:instagram/presentation/controllers/navigation_conntroller.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  // Ambil NavigationController dari GetIt (sebagai Singleton)
  final NavigationController controller = Get.put(NavigationController());

  // Siapkan daftar halaman-halaman kita

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Kita gunakan Obx untuk "mendengarkan" perubahan
      // pada selectedIndex di controller
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.pages,
        ),
      ),

      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          // Tipe 'fixed' agar label selalu terlihat
          type: BottomNavigationBarType.fixed,

          // Atur warna
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false, // Mirip UI Instagram
          showUnselectedLabels: false, // Mirip UI Instagram
          // Ambil index yang aktif dari controller
          currentIndex: controller.selectedIndex.value,

          // Panggil fungsi controller saat item diklik
          onTap: (index) => controller.changeTabIndex(index),

          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_sharp),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
