import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

class GetPostByIdUseCase {
  final PostRepository repository;
  GetPostByIdUseCase(this.repository);

  Future<Either<Failure, Post>> execute(String postId) {
    return repository.getPostById(postId);
  }
}