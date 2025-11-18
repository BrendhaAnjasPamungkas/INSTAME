import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/comment_models.dart';
import 'package:instagram/data/models/post_models.dart';
import 'package:instagram/domain/entities/post.dart';

abstract class PostRemoteDataSource {
  Stream<List<PostModel>> getPosts(List<String> followingIds);
  // Perubahan: Menerima PostModel langsung
  Future<void> createPost(PostModel post);
  // Tambahan: Fungsi khusus untuk upload gambar
  Future<String> uploadMedia(Uint8List imageBytes, PostType type);
  Stream<List<PostModel>> getUserPosts(String uid);
  Future<void> toggleLikePost(String postId, String userId);
  Stream<List<CommentModel>> getComments(String postId);
  Future<void> addComment(CommentModel comment);
  Future<void> deletePost(String postId);
  Future<void> toggleLikeComment(
    String postId,
    String commentId,
    String userId,
  );
  Future<void> deleteComment(String postId, String commentId);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore firestore;
  final CloudinaryPublic cloudinary;

  PostRemoteDataSourceImpl({required this.firestore, required this.cloudinary});

  @override
  Stream<List<PostModel>> getPosts(List<String> followingIds) {
    if (followingIds.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('posts')
        .where('authorId', whereIn: followingIds)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  // Fungsi baru untuk upload ke Cloudinary


  @override
  Future<void> createPost(PostModel post) async {
    try {
      // Simpan PostModel ke Firestore
      // Kita gunakan .doc(post.id).set(...) agar ID di Firestore sama dengan ID di model (jika sudah digenerate)
      // Atau .add(...) jika ID belum ada.
      // Di repo impl kita akan generate ID dulu, jadi pakai .doc().set() lebih aman.

      if (post.id.isEmpty) {
        await firestore.collection('posts').add(post.toJson());
      } else {
        await firestore.collection('posts').doc(post.id).set(post.toJson());
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // Hapus dokumen di dalam sub-koleksi 'comments'
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleLikeComment(
    String postId,
    String commentId,
    String userId,
  ) async {
    try {
      // Referensi ke dokumen komentar SPESIFIK di sub-koleksi
      final commentRef = firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      // Ambil data komentar saat ini
      final doc = await commentRef.get();
      if (!doc.exists) {
        throw ServerException("Komentar tidak ditemukan");
      }

      final List<String> currentLikes = List<String>.from(
        doc.data()!['likes'] ?? [],
      );

      // Logika Toggle (Sama persis seperti 'like postingan')
      if (currentLikes.contains(userId)) {
        // JIKA SUDAH LIKE -> LAKUKAN UNLIKE
        await commentRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        // JIKA BELUM LIKE -> LAKUKAN LIKE
        await commentRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<CommentModel>> getComments(String postId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommentModel.fromSnapshot(doc))
              .toList();
        });
  }

  @override
  Future<void> addComment(CommentModel comment) {
    try {
      return firestore
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .add(comment.toJson());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<PostModel>> getUserPosts(String uid) {
    return firestore
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      final doc = await postRef.get();
      if (!doc.exists) {
        throw ServerException("Postingan tidak ditemukan");
      }

      final List<String> currentLikes = List<String>.from(
        doc.data()!['likes'] ?? [],
      );

      if (currentLikes.contains(userId)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      // Hapus dokumen dari koleksi 'posts'
      await firestore.collection('posts').doc(postId).delete();

      // (Opsional: Anda juga bisa menghapus sub-koleksi 'comments' secara manual
      // jika ingin bersih-bersih, tapi Firestore tidak menghapusnya otomatis.
      // Untuk sekarang, hapus dokumen post saja sudah cukup agar hilang dari feed).
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
@override
  Future<String> uploadMedia(Uint8List bytes, PostType type) async {
    try {
      final byteData = bytes.buffer.asByteData();

      // --- INI KUNCINYA ---
      final resourceType = (type == PostType.video)
          ? CloudinaryResourceType.Video
          : CloudinaryResourceType.Image;

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          byteData,
          identifier: 'post_${DateTime.now().millisecondsSinceEpoch}',
          folder: "posts",
          resourceType: resourceType, // <-- Beri tahu Cloudinary
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      throw ServerException("Upload Gagal: ${e.message}");
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  // ... (sisa kode tetap sama)
}

