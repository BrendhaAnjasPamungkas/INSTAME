import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:instagram/domain/entities/story.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/core/errors/failures.dart';
abstract class StoryRepository {
  
  // Mengambil SEMUA story dari user yang kita follow (untuk 'cincin' di feed)
  // Kita akan filter 24 jam di sini
  Stream<Either<Failure, List<Story>>> getStories(List<String> followingIds);
  Stream<Either<Failure, List<StoryItem>>> getStoryItems(String userId);
  Future<Either<Failure, void>> deleteStory(String storyId, String authorId);
  Future<Either<Failure, void>> viewStory(String storyId, String viewerId);
  
  // Upload satu story item
  Future<Either<Failure, void>> uploadStory(Uint8List imageBytes, StoryType type, String authorId, String authorUsername, String? authorProfileUrl);
}