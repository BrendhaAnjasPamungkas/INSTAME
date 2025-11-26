import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/story_repository.dart';

class ViewStoryParams {
  final String storyId;
  final String viewerId;
  ViewStoryParams({required this.storyId, required this.viewerId});
}

class ViewStoryUseCase implements UseCase<void, ViewStoryParams> {
  final StoryRepository repository;
  ViewStoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ViewStoryParams params) async {
    return await repository.viewStory(params.storyId, params.viewerId);
  }
}