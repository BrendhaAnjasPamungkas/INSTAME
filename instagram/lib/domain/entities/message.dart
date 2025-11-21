import 'package:equatable/equatable.dart';
enum MessageType { text, image, video }
class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final MessageType type; 
  final String? mediaUrl;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text, // Default Text
    this.mediaUrl,
  });

  @override
  List<Object?> get props => [id, senderId, receiverId, text, timestamp, type, mediaUrl];
}