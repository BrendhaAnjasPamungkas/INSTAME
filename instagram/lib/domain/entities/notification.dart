import 'package:equatable/equatable.dart';

enum NotificationType { like, comment, follow }

class NotificationEntity extends Equatable {
  final String id;
  final String userId; // Pemilik notifikasi (kita)
  final String fromUserId; // Siapa yang melakukan aksi
  final String fromUsername; // Username pelaku (untuk UI cepat)
  final String? fromUserProfileUrl; // Foto pelaku
  final String? postId; // ID postingan terkait (untuk like/comment)
  final String? postImageUrl; // Foto postingan terkait
  final String? text; // Isi komentar (jika ada)
  final NotificationType type;
  final DateTime timestamp;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserProfileUrl,
    this.postId,
    this.postImageUrl,
    this.text,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, userId, fromUserId, type, timestamp];
}