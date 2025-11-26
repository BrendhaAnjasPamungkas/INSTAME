import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/story.dart';
import 'package:instagram/domain/repositories/story_repository.dart';

class GetStoriesParams {
  final List<String> followingIds;
  GetStoriesParams({required this.followingIds});
}

class GetStoriesUseCase { // Ini Stream
  final StoryRepository repository;
  GetStoriesUseCase(this.repository);

  Stream<Either<Failure, List<Story>>> execute(GetStoriesParams params) {
    return repository.getStories(params.followingIds);
  }
}