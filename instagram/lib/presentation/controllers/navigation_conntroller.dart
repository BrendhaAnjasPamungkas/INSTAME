import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instagram/core/services/event_bus.dart';
import 'package:instagram/presentation/pages/feed_page.dart';
import 'package:instagram/presentation/pages/profile_page.dart';
import 'package:instagram/presentation/pages/search_page.dart';
import 'package:instagram/presentation/pages/upload_page.dart';

class NavigationController extends GetxController {
  
  final RxInt selectedIndex = 0.obs;

  // --- PINDAHKAN LIST HALAMAN KE SINI ---
  final List<Widget> pages = [
    FeedPage(),
    SearchPage(),
    UploadPage(),
    ProfilePage(),
  ];
  late StreamSubscription _navSubscription; // <-- TAMBAHKAN INI

  @override
  void onInit() {
    super.onInit();
    // Panggil fungsi untuk mulai mendengarkan
    _listenToNavigationEvents();
  }

  void _listenToNavigationEvents() {
    // Mulai mendengarkan 'navigationStream' dari EventBus
    _navSubscription = EventBus.navigationStream.listen((event) {
      // Jika ada pesan 'TabNavigationEvent' masuk, panggil changeTabIndex
      changeTabIndex(event.tabIndex);
    });
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  @override
  void onClose() {
    // WAJIB: Hentikan 'langganan' saat controller ditutup
    // agar tidak terjadi memory leak
    _navSubscription.cancel();
    super.onClose();
  }
}