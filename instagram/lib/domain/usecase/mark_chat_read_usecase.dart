import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';

class MarkChatReadParams {
  final String chatRoomId;
  final String userId;
  MarkChatReadParams(this.chatRoomId, this.userId);
}

class MarkChatReadUseCase implements UseCase<void, MarkChatReadParams> {
  final ChatRepository repository;
  MarkChatReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkChatReadParams params) async {
    return await repository.markChatAsRead(params.chatRoomId, params.userId);
  }
}