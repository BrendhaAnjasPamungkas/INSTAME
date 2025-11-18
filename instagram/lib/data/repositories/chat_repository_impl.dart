import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/data/datasources/chat_datasource.dart';
import 'package:instagram/data/models/message_model.dart';
import 'package:instagram/domain/entities/message.dart';
import 'package:instagram/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> sendMessage(Message message) async {
    try {
      // Konversi Entity (Domain) ke Model (Data)
      final messageModel = MessageModel(
        id: message.id, // ID ini mungkin kosong, nanti di-generate Firestore
        senderId: message.senderId,
        receiverId: message.receiverId,
        text: message.text,
        timestamp: message.timestamp,
      );

      await remoteDataSource.sendMessage(messageModel);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> getMessages(String otherUserId, String currentUserId) {
    // Mengubah Stream<List<MessageModel>> menjadi Stream<Either<Failure, List<Message>>>
    return remoteDataSource.getMessages(otherUserId, currentUserId).map((messageModels) {
      // Karena MessageModel adalah turunan dari Message, kita bisa langsung me-return list-nya
      return Right<Failure, List<Message>>(messageModels);
    }).handleError((error) {
      // Menangani error jika stream putus atau gagal
      return Left<Failure, List<Message>>(ServerFailure(error.toString()));
    });
  }
}