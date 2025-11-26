import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';
class ToggleLikeCommentParams {
  final String postId;
  final String commentId;
  final String userId;

  ToggleLikeCommentParams({
    required this.postId,
    required this.commentId,
    required this.userId,
  });
}

class ToggleLikeCommentUseCase implements UseCase<void, ToggleLikeCommentParams> {
  final PostRepository repository;

  ToggleLikeCommentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleLikeCommentParams params) async {
    return await repository.toggleLikeComment(
      params.postId,
      params.commentId,
      params.userId,
    );
  }
}