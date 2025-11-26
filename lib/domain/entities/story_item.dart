import 'package:equatable/equatable.dart';

enum StoryType { image, video }

class StoryItem extends Equatable {
  final String id;
  final String url;
  final StoryType type;
  final DateTime createdAt;
  final List<String> viewedBy;
  final String authorId; // <-- TAMBAHKAN INI

  const StoryItem({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
    this.viewedBy = const [],
    required this.authorId, // <-- TAMBAHKAN INI
  });

  @override
  List<Object?> get props => [id, url, type, createdAt, authorId]; // <-- TAMBAHKAN INI
}