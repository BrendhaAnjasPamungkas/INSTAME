import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String username;
  final String email;
  final String fullName;
  final String? bio;
  final String? profileImageUrl;
  final List<String> following;
  final List<String> followers;

  const UserEntity({
    required this.uid,
    required this.username,
    required this.email,
    required this.fullName,
    this.bio,
    this.profileImageUrl,
    this.following = const [], // Default list kosong
    this.followers = const [],
  });
  UserEntity copyWith({
    String? uid,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? profileImageUrl,
    List<String>? followers,
    List<String>? following,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }

  @override
  List<Object?> get props => [uid, username, email, fullName, bio, profileImageUrl, followers, following];
}