import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/comment.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';
class GetCommentsParams {
  final String postId;
  GetCommentsParams({required this.postId});
}

class GetCommentsUseCase { // Ini Stream, jadi tidak implement UseCase
  final PostRepository repository;

  GetCommentsUseCase(this.repository);

  Stream<Either<Failure, List<CommentEntity>>> execute(GetCommentsParams params) {
    return repository.getComments(params.postId);
  }
}