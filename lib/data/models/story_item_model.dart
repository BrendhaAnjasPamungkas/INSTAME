import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram/domain/entities/story_item.dart';
class StoryItemModel extends StoryItem {
  const StoryItemModel({
    required String id,
    required String url,
    required StoryType type,
    required DateTime createdAt,
    List<String> viewedBy = const [],
    required String authorId, // <-- TAMBAHKAN INI
  }) : super(
          id: id,
          url: url,
          type: type,
          createdAt: createdAt,
          viewedBy: viewedBy,
          authorId: authorId, // <-- TAMBAHKAN INI
        );

  factory StoryItemModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return StoryItemModel(
      id: snap.id,
      url: data['url'],
      type: data['type'] == 'video' ? StoryType.video : StoryType.image,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      authorId: data['authorId'] ?? '', // <-- TAMBAHKAN INI
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type == StoryType.video ? 'video' : 'image',
        'createdAt': Timestamp.fromDate(createdAt),
        'viewedBy': viewedBy,
        'authorId': authorId, // <-- TAMBAHKAN INI
      };
}