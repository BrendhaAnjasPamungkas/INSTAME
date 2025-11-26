import 'package:equatable/equatable.dart';
enum PostType { image, video }
class Post extends Equatable {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorProfileUrl; // <-- TAMBAHKAN INI
  final String imageUrl;
  final String caption;
  final List<String> likes;
  final DateTime createdAt;
  final PostType type;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorProfileUrl, // <-- TAMBAHKAN INI (Jadikan opsional)
    required this.imageUrl,
    required this.caption,
    this.likes = const [],
    required this.createdAt,
    required this.type,
  });

  // Untuk keperluan copyWith nanti jika butuh
  Post copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorProfileUrl,
    String? imageUrl,
    String? caption,
    List<String>? likes,
    DateTime? createdAt,
    PostType? type,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorUsername,
        authorProfileUrl, // <-- TAMBAHKAN INI
        imageUrl,
        caption,
        likes,
        createdAt,
        type,
      ];
}