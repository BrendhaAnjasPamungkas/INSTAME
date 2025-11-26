import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorUsername,
    super.authorProfileUrl, // <-- TAMBAHKAN INI
    required super.imageUrl,
    required super.caption,
    super.likes,
    required super.createdAt,
    required super.type,
  });

  factory PostModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return PostModel(
      id: snap.id,
      authorId: data['authorId'],
      authorUsername: data['authorUsername'],
      authorProfileUrl: data['authorProfileUrl'], // <-- BACA DARI FIRESTORE
      imageUrl: data['imageUrl'],
      caption: data['caption'],
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'] == 'video' ? PostType.video : PostType.image,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorProfileUrl': authorProfileUrl, // <-- TULIS KE FIRESTORE
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type == PostType.video ? 'video' : 'image',
    };
  }

  @override
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorProfileUrl, // <-- TAMBAHKAN INI
    String? imageUrl,
    String? caption,
    List<String>? likes,
    DateTime? createdAt,
    PostType? type
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl, // <-- UPDATE INI
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type
    );
  }
}