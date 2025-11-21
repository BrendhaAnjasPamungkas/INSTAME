import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Stream<List<NotificationModel>> getNotifications(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;

  NotificationRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    // Ambil notifikasi dimana 'userId' (penerima) adalah kita
    // Urutkan dari yang terbaru
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId) 
        .orderBy('timestamp', descending: true) 
        .limit(50) // Batasi 50 notifikasi terakhir agar ringan
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromSnapshot(doc))
          .toList();
    });
  }
}