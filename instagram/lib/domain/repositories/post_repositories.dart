import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/comment.dart';
import 'package:instagram/domain/entities/post.dart';

abstract class PostRepository {
  // Kita pakai Stream agar feed otomatis update jika ada data baru
  Stream<Either<Failure, List<Post>>> getPosts(List<String> followingIds);
  Future<Either<Failure, void>> createPost(Uint8List imageBytes, String caption, String authorId, String authorUsername, String? authorProfileUrl, PostType type);
  Stream<Either<Failure, List<Post>>> getUserPosts(String uid);
  Future<Either<Failure, void>> toggleLikePost(String postId, String userId);
  Stream<Either<Failure, List<CommentEntity>>> getComments(String postId);
  Future<Either<Failure, void>> addComment(CommentEntity comment);
  Future<Either<Failure, void>> deletePost(String postId);
  Future<Either<Failure, void>> toggleLikeComment(String postId, String commentId, String userId);
  Future<Either<Failure, void>> deleteComment(String postId, String commentId);
  Future<Either<Failure, Post>> getPostById(String postId);
  
}