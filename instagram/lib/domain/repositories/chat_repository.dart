import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, void>> sendMessage(Message message);
  Stream<Either<Failure, List<Message>>> getMessages(String otherUserId, String currentUserId);
}