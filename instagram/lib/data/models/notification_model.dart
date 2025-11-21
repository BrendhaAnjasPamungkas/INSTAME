import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/notification.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.fromUserId,
    required super.fromUsername,
    super.fromUserProfileUrl,
    super.postId,
    super.postImageUrl,
    super.text,
    required super.type,
    required super.timestamp,
  });

  factory NotificationModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    
    NotificationType type = NotificationType.like;
    if (data['type'] == 'comment') type = NotificationType.comment;
    if (data['type'] == 'follow') type = NotificationType.follow;

    return NotificationModel(
      id: snap.id,
      userId: data['userId'],
      fromUserId: data['fromUserId'],
      fromUsername: data['fromUsername'],
      fromUserProfileUrl: data['fromUserProfileUrl'],
      postId: data['postId'],
      postImageUrl: data['postImageUrl'],
      text: data['text'],
      type: type,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr = 'like';
    if (type == NotificationType.comment) typeStr = 'comment';
    if (type == NotificationType.follow) typeStr = 'follow';

    return {
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserProfileUrl': fromUserProfileUrl,
      'postId': postId,
      'postImageUrl': postImageUrl,
      'text': text,
      'type': typeStr,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}