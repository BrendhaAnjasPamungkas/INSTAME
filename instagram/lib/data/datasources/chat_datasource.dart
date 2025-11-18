import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<void> sendMessage(MessageModel message);
  Stream<List<MessageModel>> getMessages(String otherUserId, String currentUserId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  ChatRemoteDataSourceImpl({required this.firestore});

  // --- LOGIKA ID UNIK (PENTING) ---
  // Menggabungkan 2 ID dengan urutan abjad agar ID Chat Room selalu sama
  // misal: UserA chat UserB -> ID: "UserA_UserB"
  // misal: UserB chat UserA -> ID: "UserA_UserB" (Sama!)
  String _getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Urutkan abjad
    return ids.join("_");
  }
  // --------------------------------

  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      final chatRoomId = _getChatRoomId(message.senderId, message.receiverId);
      
      // Simpan pesan ke sub-koleksi 'messages'
      await firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toJson());
          
      // (Nanti di Tahap 2 kita akan update 'lastMessage' di sini untuk Inbox)
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<MessageModel>> getMessages(String otherUserId, String currentUserId) {
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);

    return firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Pesan lama di atas
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromSnapshot(doc)).toList();
    });
  }
}