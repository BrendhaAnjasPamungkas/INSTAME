import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/message.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';

class GetMessagesParams {
  final String otherUserId;
  final String currentUserId;
  GetMessagesParams({required this.otherUserId, required this.currentUserId});
}

class GetMessagesUseCase { // Stream, tidak perlu implements UseCase
  final ChatRepository repository;
  GetMessagesUseCase(this.repository);

  Stream<Either<Failure, List<Message>>> execute(GetMessagesParams params) {
    return repository.getMessages(params.otherUserId, params.currentUserId);
  }
}