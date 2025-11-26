import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/message_model.dart';
import 'package:instagram/domain/entities/chat_room.dart';
import 'package:instagram/domain/entities/message.dart';

abstract class ChatRemoteDataSource {
  Future<void> sendMessage(MessageModel message);
  Stream<List<MessageModel>> getMessages(
    String otherUserId,
    String currentUserId,
  );
  Stream<List<ChatRoom>> getChatRooms(String currentUserId);
  Future<String> uploadChatMedia(Uint8List bytes, MessageType type);
  Future<void> deleteMessage(String messageId, String chatRoomId);
  Future<void> markChatAsRead(String chatRoomId, String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final CloudinaryPublic cloudinary;
  
  ChatRemoteDataSourceImpl({required this.firestore, required this.cloudinary});

  // --- LOGIKA ID UNIK ---
  String _getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); 
    return ids.join("_");
  }

 @override
  Stream<List<ChatRoom>> getChatRooms(String currentUserId) {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final List<dynamic> participants = data['participants'];
            final String otherId = participants.firstWhere((id) => id != currentUserId, orElse: () => "");

            // --- CEK APAKAH UNREAD ---
            final List<dynamic> unreadBy = data['unreadBy'] ?? [];
            final bool isUnread = unreadBy.contains(currentUserId);
            // -------------------------

            return ChatRoom(
              id: data['id'],
              otherUserId: otherId,
              lastMessage: data['lastMessage'] ?? "",
              lastTimestamp: (data['lastTimestamp'] as Timestamp).toDate(),
              isUnread: isUnread, // <-- Masukkan ke entity
            );
          }).toList();
        });
  }
  @override
  Future<void> deleteMessage(String messageId, String chatRoomId) async {
    try {
      // Hapus pesan dari sub-koleksi
      await firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
          
      // (Opsional: Update 'lastMessage' di induk jika pesan terakhir dihapus.
      //  Ini agak kompleks, untuk sekarang kita hapus pesannya saja).
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  @override
  Future<void> markChatAsRead(String chatRoomId, String userId) async {
    try {
      // Hapus ID kita dari daftar unreadBy
      await firestore.collection('chats').doc(chatRoomId).update({
        'unreadBy': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      // Silent fail oke
    }
  }

 @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      final chatRoomId = _getChatRoomId(message.senderId, message.receiverId);
      
      // 1. Simpan Pesan
      await firestore.collection('chats').doc(chatRoomId).collection('messages').add(message.toJson());
          
      // 2. Update Induk (Metadata)
      String previewMsg = message.text;
      if (message.type == MessageType.image) previewMsg = "📷 Foto";
      if (message.type == MessageType.video) previewMsg = "🎥 Video";

      await firestore.collection('chats').doc(chatRoomId).set({
        'participants': [message.senderId, message.receiverId],
        'lastMessage': previewMsg,
        'lastTimestamp': message.timestamp,
        'id': chatRoomId,
        // --- TAMBAHKAN INI ---
        // Masukkan ID Penerima ke daftar 'unreadBy' (agar di HP dia jadi bold)
        'unreadBy': FieldValue.arrayUnion([message.receiverId]), 
        // ---------------------
      }, SetOptions(merge: true));

    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<MessageModel>> getMessages(
    String otherUserId,
    String currentUserId,
  ) {
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);

    return firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromSnapshot(doc))
              .toList();
        });
  }

  @override
  Future<String> uploadChatMedia(Uint8List bytes, MessageType type) async {
    try {
      final byteData = bytes.buffer.asByteData();
      
      final resourceType = (type == MessageType.video)
          ? CloudinaryResourceType.Video
          : CloudinaryResourceType.Image;

      // --- PERBAIKAN DI SINI ---
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          byteData,
          identifier: 'chat_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: resourceType,
          // HAPUS 'folder' DARI SINI
          folder: "chats",
        ),
         // PINDAHKAN KE SINI (Parameter uploadFile)
      );
      // -------------------------
      
      return response.secureUrl;
    } catch (e) {
      throw ServerException("Gagal upload media chat: $e");
    }
  }
}