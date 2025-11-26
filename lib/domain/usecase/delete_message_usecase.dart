import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';

class DeleteMessageParams {
  final String messageId;
  final String senderId;
  final String receiverId;

  DeleteMessageParams({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
  });
}

class DeleteMessageUseCase implements UseCase<void, DeleteMessageParams> {
  final ChatRepository repository;

  DeleteMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) async {
    return await repository.deleteMessage(
      params.messageId,
      params.senderId,
      params.receiverId,
    );
  }
}