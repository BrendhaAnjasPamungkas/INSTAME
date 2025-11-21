import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.text,
    required super.timestamp,
    super.type,
    super.mediaUrl
  });

  factory MessageModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    MessageType msgType = MessageType.text;
    if (data['type'] == 'image') msgType = MessageType.image;
    if (data['type'] == 'video') msgType = MessageType.video;
    return MessageModel(
      id: snap.id,
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      text: data['text'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: msgType,
      mediaUrl: data['mediaUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    String typeString = 'text';
    if (type == MessageType.image) typeString = 'image';
    if (type == MessageType.video) typeString = 'video';
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': typeString,
      'mediaUrl': mediaUrl,
    };
  }
}