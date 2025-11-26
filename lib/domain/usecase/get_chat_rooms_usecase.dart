import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/chat_room.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';

class GetChatRoomsParams {
  final String currentUserId;
  GetChatRoomsParams(this.currentUserId);
}

class GetChatRoomsUseCase {
  final ChatRepository repository;
  GetChatRoomsUseCase(this.repository);

  Stream<Either<Failure, List<ChatRoom>>> execute(GetChatRoomsParams params) {
    return repository.getChatRooms(params.currentUserId);
  }
}