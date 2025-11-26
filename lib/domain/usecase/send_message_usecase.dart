import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/message.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';

class SendMessageParams {
  final Message message;
  SendMessageParams(this.message);
}

class SendMessageUseCase implements UseCase<void, SendMessageParams> {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) async {
    return await repository.sendMessage(params.message);
  }
}