import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:instagram/data/datasources/story_datasource.dart';
import 'package:instagram/domain/entities/story.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/domain/repositories/story_repository.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/core/errors/failures.dart';

class StoryRepositoryImpl implements StoryRepository {
  final StoryRemoteDataSource remoteDataSource;

  StoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<Story>>> getStories(List<String> followingIds) {
    return remoteDataSource.getStories(followingIds).map((stories) {
      return Right<Failure, List<Story>>(stories);
    }).handleError((error) {
      return Left<Failure, List<Story>>(ServerFailure(error.toString()));
    });
  }

  @override
  Stream<Either<Failure, List<StoryItem>>> getStoryItems(String userId) {
    return remoteDataSource.getStoryItems(userId).map((items) {
      return Right<Failure, List<StoryItem>>(items);
    }).handleError((error) {
      return Left<Failure, List<StoryItem>>(ServerFailure(error.toString()));
    });
  }

  @override
  Future<Either<Failure, void>> uploadStory(Uint8List imageBytes, StoryType type, String authorId, String authorUsername, String? authorProfileUrl) async {
    try {
      await remoteDataSource.uploadStory(
        imageBytes,
        type,
        authorId,
        authorUsername,
        authorProfileUrl,
      );
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> deleteStory(String storyId, String authorId) async {
    try {
      await remoteDataSource.deleteStory(storyId,authorId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
  Future<Either<Failure, void>> viewStory(String storyId, String viewerId) async {
    try {
      await remoteDataSource.viewStory(storyId, viewerId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}