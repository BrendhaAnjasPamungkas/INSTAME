import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/story_item.dart';
import 'package:instagram/domain/repositories/story_repository.dart';

class UploadStoryParams {
  final Uint8List imageBytes;
  final StoryType type;
  final String authorId;
  final String authorUsername;
  final String? authorProfileUrl;

  UploadStoryParams({
    required this.imageBytes,
    required this.type,
    required this.authorId,
    required this.authorUsername,
    this.authorProfileUrl,
  });
}

class UploadStoryUseCase implements UseCase<void, UploadStoryParams> {
  final StoryRepository repository;
  UploadStoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UploadStoryParams params) async {
    return await repository.uploadStory(
      params.imageBytes,
      params.type,
      params.authorId,
      params.authorUsername,
      params.authorProfileUrl,
    );
  }
}