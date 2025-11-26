import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String postId; // ID postingan tempat komentar ini berada
  final String authorId;
  final String authorUsername;
  final String? authorProfileUrl;
  final String content;
  final DateTime createdAt;
  final List<String> likes; // Siapa saja yang 'like' komentar ini
  final String? parentId;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
    this.authorProfileUrl,
    this.likes = const [],
    this.parentId,
  });

  int get likeCount => likes.length;

  @override
  List<Object?> get props => [id, postId, authorId, content, createdAt, likes, parentId];
}