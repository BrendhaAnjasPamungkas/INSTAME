import 'dart:async';

// Ini adalah kelas pesan/event yang akan kita kirim
class TabNavigationEvent {
  final int tabIndex;
  TabNavigationEvent(this.tabIndex);
}

class FetchFeedEvent{}
class ProfileUpdateEvent{}
class LogoutEvent{}

// Ini adalah "Saluran Pipa" global kita
class EventBus {
  // 1. Buat StreamController
  // 'broadcast' berarti banyak yang bisa mendengarkan
  static final StreamController<TabNavigationEvent> _navController = StreamController<TabNavigationEvent>.broadcast();

  // 2. Buat Stream (saluran keluar) yang bisa didengarkan
  static Stream<TabNavigationEvent> get navigationStream => _navController.stream;

  // 3. Buat fungsi untuk mengirim pesan (saluran masuk)
  static void fire(TabNavigationEvent event) {
    _navController.add(event);
  }
  static final StreamController<ProfileUpdateEvent> _profileController = StreamController<ProfileUpdateEvent>.broadcast();
  static Stream<ProfileUpdateEvent> get profileStream => _profileController.stream;
  static void fireProfileUpdate(ProfileUpdateEvent event) { _profileController.add(event); }

  // (Kita bisa tambahkan stream lain di sini nanti, misal UserProfileUpdatedEvent)
  static final StreamController<FetchFeedEvent> _feedController = StreamController<FetchFeedEvent>.broadcast();
  static Stream<FetchFeedEvent> get feedStream => _feedController.stream;
  static void fireFeed(FetchFeedEvent event) { _feedController.add(event); }

  static final StreamController<LogoutEvent> _logoutController = StreamController<LogoutEvent>.broadcast();
  static Stream<LogoutEvent> get logoutStream => _logoutController.stream;
  static void fireLogout(LogoutEvent event) { _logoutController.add(event); }
}