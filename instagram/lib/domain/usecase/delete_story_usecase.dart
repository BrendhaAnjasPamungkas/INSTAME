import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/story_repository.dart';

class DeleteStoryParams {
  final String storyId;
  final String authorId;
  DeleteStoryParams({required this.storyId, required this.authorId});
}

class DeleteStoryUseCase implements UseCase<void, DeleteStoryParams> {
  final StoryRepository repository;

  DeleteStoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteStoryParams params) async {
    return await repository.deleteStory(params.storyId, params.authorId);
  }
}
