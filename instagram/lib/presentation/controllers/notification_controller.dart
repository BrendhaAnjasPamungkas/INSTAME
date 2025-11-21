import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/domain/usecase/get_notification_usecase.dart';
import 'package:instagram/injection_container.dart';

class NotificationController extends GetxController {
  final GetNotificationsUseCase getNotificationsUseCase = locator();
  final FirebaseAuth auth = locator();

  var notifications = <NotificationEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      notifications.bindStream(getNotificationsUseCase.execute(uid).map((either) {
        return either.fold((l) => [], (r) => r);
      }));
    }
  }
}