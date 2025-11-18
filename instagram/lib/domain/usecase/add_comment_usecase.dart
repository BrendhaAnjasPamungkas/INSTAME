import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/comment.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';
class AddCommentParams {
  final CommentEntity comment;
  AddCommentParams({required this.comment});
}

class AddCommentUseCase implements UseCase<void, AddCommentParams> {
  final PostRepository repository;

  AddCommentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddCommentParams params) async {
    return await repository.addComment(params.comment);
  }
}