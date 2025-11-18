import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

// Params akan berisi 'uid'
class GetUserPostsParams {
  final String uid;
  GetUserPostsParams(this.uid);
}

// Ini adalah Stream, jadi tidak meng-implement 'UseCase'
class GetUserPostsUseCase {
  final PostRepository repository;

  GetUserPostsUseCase(this.repository);

  // Kita pakai 'execute' bukan 'call'
  Stream<Either<Failure, List<Post>>> execute(GetUserPostsParams params) {
    return repository.getUserPosts(params.uid);
  }
}