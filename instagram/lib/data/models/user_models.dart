import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/user.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String uid,
    required String username,
    required String email,
    required String fullName,
    String? bio,
    String? profileImageUrl,
    List<String> following = const [], // <-- TAMBAHKAN
    List<String> followers = const [],
  }) : super(
    uid: uid,
    username: username,
    email: email,
    fullName: fullName,
    bio: bio,
    profileImageUrl: profileImageUrl,
    following: following, // <-- TAMBAHKAN
    followers: followers,
  );
  

  // Konversi dari Dokumen Firestore ke UserModel
  factory UserModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    final List<String> followingList = List<String>.from(data['following'] ?? []);
    final List<String> followersList = List<String>.from(data['followers'] ?? []);
    return UserModel(
      uid: snap.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      following: followingList, // <-- TAMBAHKAN
      followers: followersList, // <-- TAMBAHKAN
    );
  }

  // Konversi dari UserModel ke JSON (untuk disimpan ke Firestore)
  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'fullName': fullName,
    'bio': bio ?? '', // Default ke string kosong
    'profileImageUrl': profileImageUrl,
    'uid': uid, // Simpan uid juga di dalam dokumen
    'following': following, // <-- TAMBAHKAN
    'followers': followers, // <-- TAMBAHKAN
  };
}