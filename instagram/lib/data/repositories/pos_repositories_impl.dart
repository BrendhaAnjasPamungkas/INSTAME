import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/data/datasources/post_datasource.dart';
import 'package:instagram/data/models/comment_models.dart';
import 'package:instagram/data/models/post_models.dart';
import 'package:instagram/domain/entities/comment.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<Post>>> getPosts(List<String> followingIds) {
    return remoteDataSource.getPosts(followingIds).map((posts) {
      // Sorting di sisi klien
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right<Failure, List<Post>>(posts);
    }).handleError((error) {
      return Left<Failure, List<Post>>(ServerFailure(error.toString()));
    });
  }

  @override
  Stream<Either<Failure, List<Post>>> getUserPosts(String uid) {
    return remoteDataSource.getUserPosts(uid).map((posts) {
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right<Failure, List<Post>>(posts);
    }).handleError((error) {
      return Left<Failure, List<Post>>(ServerFailure(error.toString()));
    });
  }
  
  @override
  Future<Either<Failure, Post>> getPostById(String postId) async {
    try {
      final post = await remoteDataSource.getPostById(postId);
      return Right(post);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createPost(
    Uint8List imageBytes,
    String caption,
    String authorId,
    String authorUsername,
    String? authorProfileUrl,
    PostType type,
  ) async {
    try {
      // 1. Upload Media
      String imageUrl = await remoteDataSource.uploadMedia(imageBytes, type);

      // 2. Buat PostModel
      final post = PostModel(
        id: '', // ID diisi Firestore
        authorId: authorId,
        authorUsername: authorUsername,
        authorProfileUrl: authorProfileUrl,
        imageUrl: imageUrl,
        caption: caption,
        createdAt: DateTime.now(),
        likes: [],
        type: type,
      );

      // 3. Simpan
      await remoteDataSource.createPost(post);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLikePost(String postId, String userId) async {
    try {
      await remoteDataSource.toggleLikePost(postId, userId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // --- COMMENTS ---

  @override
  Stream<Either<Failure, List<CommentEntity>>> getComments(String postId) {
    return remoteDataSource.getComments(postId).map((comments) {
      return Right<Failure, List<CommentEntity>>(comments);
    }).handleError((error) {
      return Left<Failure, List<CommentEntity>>(ServerFailure(error.toString()));
    });
  }

  @override
  Future<Either<Failure, void>> addComment(CommentEntity comment) async {
    try {
      final commentModel = CommentModel(
        id: '', 
        postId: comment.postId,
        authorId: comment.authorId,
        authorUsername: comment.authorUsername,
        authorProfileUrl: comment.authorProfileUrl,
        content: comment.content,
        createdAt: comment.createdAt,
        likes: comment.likes,
        parentId: comment.parentId,
      );
      
      await remoteDataSource.addComment(commentModel);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String postId, String commentId) async {
    try {
      await remoteDataSource.deleteComment(postId, commentId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLikeComment(String postId, String commentId, String userId) async {
    try {
      await remoteDataSource.toggleLikeComment(postId, commentId, userId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}