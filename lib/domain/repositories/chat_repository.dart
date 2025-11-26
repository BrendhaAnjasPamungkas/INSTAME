import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/chat_room.dart';
import 'package:instagram/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, void>> sendMessage(Message message);
  Stream<Either<Failure, List<Message>>> getMessages(String otherUserId, String currentUserId);
  Stream<Either<Failure, List<ChatRoom>>> getChatRooms(String currentUserId);
  Future<Either<Failure, void>> deleteMessage(String messageId, String senderId, String receiverId);
  Future<Either<Failure, void>> markChatAsRead(String chatRoomId, String userId);
}