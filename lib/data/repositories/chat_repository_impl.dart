import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/data/datasources/chat_datasource.dart';
import 'package:instagram/data/models/message_model.dart';
import 'package:instagram/domain/entities/chat_room.dart';
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
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        text: message.text,
        timestamp: message.timestamp,
        
        // --- INI YANG HILANG SEBELUMNYA ---
        type: message.type, 
        mediaUrl: message.mediaUrl,
        // ----------------------------------
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
  Future<Either<Failure, void>> markChatAsRead(String chatRoomId, String userId) async {
    try {
      await remoteDataSource.markChatAsRead(chatRoomId, userId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
  // ...
  
  @override
  Stream<Either<Failure, List<ChatRoom>>> getChatRooms(String currentUserId) {
    return remoteDataSource.getChatRooms(currentUserId).map((rooms) {
      return Right<Failure, List<ChatRoom>>(rooms);
    }).handleError((error) {
      return Left<Failure, List<ChatRoom>>(ServerFailure(error.toString()));
    });
  }
    @override
  Future<Either<Failure, void>> deleteMessage(String messageId, String senderId, String receiverId) async {
    try {
      // REKONSTRUKSI ID CHAT ROOM DI SINI (LOGIKA SAMA DENGAN DATASOURCE)
      // Atau biarkan datasource yang handle logic ID-nya jika fungsi _getChatRoomId public.
      // Tapi karena _getChatRoomId private di datasource, kita bisa kirim sender/receiver,
      // lalu biarkan datasource menghitung ID-nya, ATAU kita duplikasi logika sorting string.
      
      // CARA TERBAIK: Update interface datasource agar menerima sender/receiver
      // Tapi untuk cepat, kita kirim chatRoomId dari sini:
      
      List<String> ids = [senderId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await remoteDataSource.deleteMessage(messageId, chatRoomId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}