import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/story.dart';

class StoryModel extends Story {
  const StoryModel({
    required String id,
    required String username,
    String? profileImageUrl,
    required DateTime lastStoryAt,
  }) : super(
          id: id,
          username: username,
          profileImageUrl: profileImageUrl,
          lastStoryAt: lastStoryAt,
        );

  // Konversi dari Dokumen Firebase (Map) ke Model
  factory StoryModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return StoryModel(
      id: snap.id, // ID Dokumen = UID Pengguna
      username: data['username'],
      profileImageUrl: data['profileImageUrl'],
      lastStoryAt: (data['lastStoryAt'] as Timestamp).toDate(),
    );
  }

  // Konversi dari Model ke Map (untuk upload ke Firestore)
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'lastStoryAt': Timestamp.fromDate(lastStoryAt),
      };
}