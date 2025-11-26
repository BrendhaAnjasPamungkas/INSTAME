import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/comment.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required String id,
    required String postId,
    required String authorId,
    required String authorUsername,
    required String content,
    required DateTime createdAt,
    String? authorProfileUrl,
    List<String> likes = const [],
    super.parentId,
  }) : super(
          id: id,
          postId: postId,
          authorId: authorId,
          authorUsername: authorUsername,
          content: content,
          createdAt: createdAt,
          authorProfileUrl: authorProfileUrl,
          likes: likes,
          
        );

  // Konversi dari Dokumen Firebase (Map) ke CommentModel
  factory CommentModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    
    return CommentModel(
      id: snap.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorProfileUrl: data['authorProfileUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      parentId: data['parentId'],
    );
  }

  // Konversi dari CommentModel ke Map (untuk upload ke Firestore)
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'authorId': authorId,
        'authorUsername': authorUsername,
        'authorProfileUrl': authorProfileUrl,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'likes': likes,
        'parentId': parentId,
      };
}