import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/comment_models.dart';
import 'package:instagram/data/models/notification_model.dart';
import 'package:instagram/data/models/post_models.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/domain/entities/post.dart'; // Untuk PostType

abstract class PostRemoteDataSource {
  Stream<List<PostModel>> getPosts(List<String> followingIds);
  Future<void> createPost(PostModel post);
  Future<String> uploadMedia(Uint8List bytes, PostType type);
  Stream<List<PostModel>> getUserPosts(String uid);
  Future<void> toggleLikePost(String postId, String userId);
  
  Stream<List<CommentModel>> getComments(String postId);
  Future<void> addComment(CommentModel comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<void> toggleLikeComment(String postId, String commentId, String userId);
  
  Future<void> deletePost(String postId);
  Future<PostModel> getPostById(String postId);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore firestore;
  final CloudinaryPublic cloudinary;

  PostRemoteDataSourceImpl({required this.firestore, required this.cloudinary});

  // --- FEED & POSTS ---

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

  @override
  Future<String> uploadMedia(Uint8List bytes, PostType type) async {
    try {
      final byteData = bytes.buffer.asByteData();
      final resourceType = (type == PostType.video)
          ? CloudinaryResourceType.Video
          : CloudinaryResourceType.Image;

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          byteData,
          identifier: 'post_${DateTime.now().millisecondsSinceEpoch}',
          folder: "posts", // Folder di sini (sebagai parameter)
          resourceType: resourceType,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw ServerException("Upload Gagal: $e");
    }
  }

  @override
  Future<void> createPost(PostModel post) async {
    try {
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
  Future<PostModel> getPostById(String postId) async {
    try {
      final doc = await firestore.collection('posts').doc(postId).get();
      if (!doc.exists) {
        throw ServerException("Postingan tidak ditemukan");
      }
      return PostModel.fromSnapshot(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await firestore.collection('posts').doc(postId).delete();
      // Opsional: Hapus sub-koleksi comments jika perlu (manual di client atau cloud function)
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      final doc = await postRef.get();
      
      if (!doc.exists) throw ServerException("Postingan tidak ditemukan");

      final List<String> currentLikes = List<String>.from(doc.data()!['likes'] ?? []);

      if (currentLikes.contains(userId)) {
        // UNLIKE
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        // LIKE
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });

        // Kirim Notifikasi Like
        final postAuthorId = doc.data()!['authorId'];
        final postImage = doc.data()!['imageUrl'];
        
        _sendNotification(
          toUserId: postAuthorId,
          currentUserId: userId,
          type: NotificationType.like,
          postId: postId,
          postImageUrl: postImage,
        );
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // --- COMMENTS ---

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
  Future<void> addComment(CommentModel comment) async {
    try {
      // 1. Simpan Komentar
      await firestore
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .add(comment.toJson());

      // 2. Kirim Notifikasi
      final postDoc = await firestore.collection('posts').doc(comment.postId).get();

      if (postDoc.exists) {
        final postData = postDoc.data()!;
        _sendNotification(
          toUserId: postData['authorId'],
          currentUserId: comment.authorId,
          type: NotificationType.comment,
          postId: comment.postId,
          postImageUrl: postData['imageUrl'],
          text: comment.content,
        );
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
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
  Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
    try {
      final commentRef = firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      final doc = await commentRef.get();
      if (!doc.exists) throw ServerException("Komentar tidak ditemukan");

      final List<String> currentLikes = List<String>.from(doc.data()!['likes'] ?? []);

      if (currentLikes.contains(userId)) {
        await commentRef.update({'likes': FieldValue.arrayRemove([userId])});
      } else {
        await commentRef.update({'likes': FieldValue.arrayUnion([userId])});
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // --- HELPER NOTIFIKASI ---
  Future<void> _sendNotification({
    required String toUserId,
    required String currentUserId,
    required NotificationType type,
    String? postId,
    String? text,
    String? postImageUrl,
  }) async {
    if (toUserId == currentUserId) return; // Jangan notif diri sendiri

    try {
      final userDoc = await firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data()!;

      final notif = NotificationModel(
        id: '', // Firestore generate ID
        userId: toUserId,
        fromUserId: currentUserId,
        fromUsername: userData['username'],
        fromUserProfileUrl: userData['profileImageUrl'],
        type: type,
        postId: postId,
        postImageUrl: postImageUrl,
        text: text,
        timestamp: DateTime.now(),
      );

      await firestore.collection('notifications').add(notif.toJson());
    } catch (e) {
      print("Gagal kirim notifikasi: $e");
    }
  }
}