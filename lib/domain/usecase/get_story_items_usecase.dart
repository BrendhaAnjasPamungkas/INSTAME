import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/domain/repositories/story_repository.dart';
class GetStoryItemsParams {
  final String userId;
  GetStoryItemsParams({required this.userId});
}

class GetStoryItemsUseCase { // Ini Stream
  final StoryRepository repository;
  GetStoryItemsUseCase(this.repository);

  Stream<Either<Failure, List<StoryItem>>> execute(GetStoryItemsParams params) {
    return repository.getStoryItems(params.userId);
  }
}