import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id; // Ini akan jadi UID pengguna
  final String username;
  final String? profileImageUrl;// Daftar semua story item dari user ini
  final DateTime lastStoryAt;

  const Story({
    required this.id,
    required this.username,
    this.profileImageUrl,

    required this.lastStoryAt
  });

  @override
  List<Object?> get props => [id, username, profileImageUrl, lastStoryAt];
}