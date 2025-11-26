import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

class ToggleLikePostParams {
  final String postId;
  final String userId;

  ToggleLikePostParams({required this.postId, required this.userId});
}

class ToggleLikePostUseCase implements UseCase<void, ToggleLikePostParams> {
  final PostRepository repository;

  ToggleLikePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleLikePostParams params) async {
    return await repository.toggleLikePost(params.postId, params.userId);
  }
}