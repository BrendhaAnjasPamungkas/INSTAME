import 'package:equatable/equatable.dart';

class ChatRoom extends Equatable {
  final String id; // ID Chat Room (uidA_uidB)
  final String otherUserId; // ID Lawan bicara
  final String lastMessage;
  final DateTime lastTimestamp;
  final bool isUnread;

  const ChatRoom({
    required this.id,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastTimestamp,
    this.isUnread = false,
  });

  @override
  List<Object?> get props => [id, otherUserId, lastMessage, lastTimestamp, isUnread];
}