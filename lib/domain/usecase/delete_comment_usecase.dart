import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

class DeleteCommentParams {
  final String postId;
  final String commentId;
  DeleteCommentParams({required this.postId, required this.commentId});
}

class DeleteCommentUseCase implements UseCase<void, DeleteCommentParams> {
  final PostRepository repository;

  DeleteCommentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCommentParams params) async {
    return await repository.deleteComment(params.postId, params.commentId);
  }
}