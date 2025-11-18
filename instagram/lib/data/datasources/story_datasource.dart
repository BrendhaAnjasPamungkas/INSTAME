import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/story_item_model.dart';
import 'package:instagram/data/models/story_model.dart';
import 'package:instagram/domain/entities/story_item.dart'; // Untuk StoryType

abstract class StoryRemoteDataSource {
  Stream<List<StoryModel>> getStories(List<String> followingIds);
  Stream<List<StoryItemModel>> getStoryItems(String userId);
  Future<void> uploadStory(
    Uint8List imageBytes,
    StoryType type,
    String authorId,
    String authorUsername,
    String? authorProfileUrl,
  );
 Future<void> viewStory(String storyId, String viewerId);
 Future<void> deleteStory(String storyId, String authorId);
}

class StoryRemoteDataSourceImpl implements StoryRemoteDataSource {
  final FirebaseFirestore firestore;
  final CloudinaryPublic cloudinary;

  StoryRemoteDataSourceImpl({
    required this.firestore,
    required this.cloudinary,
  });

  // --- LOGIKA FILTER 24 JAM ---
  DateTime get _24HoursAgo =>
      DateTime.now().subtract(const Duration(hours: 24));
  // ---

  @override
  Stream<List<StoryModel>> getStories(List<String> followingIds) {
    if (followingIds.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('stories_metadata')
        .where('id', whereIn: followingIds)
        // --- PASTIKAN BARIS INI AKTIF (TIDAK DI-KOMENTAR) ---
        .where('lastStoryAt', isGreaterThan: _24HoursAgo)
        // ----------------------------------------------------
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryModel.fromSnapshot(doc))
              .toList();
        });
  }
  @override
  Future<void> viewStory(String storyId, String viewerId) async {
    try {
      // Tambahkan viewerId ke array 'viewedBy' (arrayUnion mencegah duplikat)
      await firestore.collection('stories_items').doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([viewerId])
      });
    } catch (e) {
      // Abaikan error jika story sudah dihapus atau masalah koneksi minor
      // View count tidak kritikal
    }
  }

  @override
  Stream<List<StoryItemModel>> getStoryItems(String userId) {
    // Kueri 'item' (fotonya)
    return firestore
        .collection('stories_items') // <-- HAPUS SUB-KOLEKSINYA
        .where('authorId', isEqualTo: userId) // <-- TAMBAHKAN FILTER INI
        .where('createdAt', isGreaterThan: _24HoursAgo) // <-- FILTER 24 JAM
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryItemModel.fromSnapshot(doc))
              .toList();
        });
  }

  @override
  Future<void> uploadStory(
    Uint8List imageBytes,
    StoryType type,
    String authorId,
    String authorUsername,
    String? authorProfileUrl,
  ) async {
    try {
      final byteData = imageBytes.buffer.asByteData();

      // --- INI PERBAIKANNYA ---
      // Tentukan resource type berdasarkan StoryType
      final resourceType = (type == StoryType.video)
          ? CloudinaryResourceType.Video
          : CloudinaryResourceType.Image;

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          byteData,
          identifier:
              'story_${authorId}_${DateTime.now().millisecondsSinceEpoch}',
          folder: "stories",
          resourceType:
              resourceType, // <-- PENTING: Beri tahu Cloudinary ini Video/Image
        ),
      );
      // ------------------------

      String imageUrl = response.secureUrl;

      // ... (Sisa kode pembuatan StoryItemModel dan Batch Write TETAP SAMA)
      final now = DateTime.now();
      final storyItem = StoryItemModel(
        id: '',
        url: imageUrl,
        type:
            type, // Ini akan disimpan ke Firestore sebagai 'video' atau 'image'
        createdAt: now,
        viewedBy: [],
        authorId: authorId,
      );

      // ... (Sisa kode batch commit TETAP SAMA)
      final storyMetadata = StoryModel(
        id: authorId,
        username: authorUsername,
        profileImageUrl: authorProfileUrl,
        lastStoryAt: now,
      );

      final batch = firestore.batch();
      final itemRef = firestore.collection('stories_items').doc();
      batch.set(itemRef, storyItem.toJson());
      final metaRef = firestore.collection('stories_metadata').doc(authorId);
      batch.set(metaRef, storyMetadata.toJson());

      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteStory(String storyId, String authorId) async {
    try {
      // Hapus dokumen dari koleksi 'stories_items'
      await firestore.collection('stories_items').doc(storyId).delete();
      final snapshot = await firestore
          .collection('stories_items')
          .where('authorId', isEqualTo: authorId)
          .limit(1) // Cukup cari 1 saja
          .get();

      // 3. Jika TIDAK ADA story tersisa (kosong)
      if (snapshot.docs.isEmpty) {
        // Hapus Metadata (Cincin)
        await firestore.collection('stories_metadata').doc(authorId).delete();
      }

      // (Catatan: Kita tidak menghapus metadata 'cincin' di sini agar lebih cepat.
      // Cincin akan hilang sendiri setelah 24 jam atau saat refresh berikutnya jika kosong)
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
