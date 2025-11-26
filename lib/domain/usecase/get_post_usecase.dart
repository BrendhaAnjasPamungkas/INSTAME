import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart'; // Impor base class NoParams
import 'package:instagram/domain/entities/post.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

class GetPostsParams {
  // Daftar 'uid' orang yang kita ikuti
  final List<String> followingIds;
  GetPostsParams({required this.followingIds});
}

class GetPostsUseCase {
  // Tidak pakai base class Usecase karena ini Stream
  final PostRepository repository;

  GetPostsUseCase(this.repository);

  // Kita tidak pakai call() karena ini Stream
  Stream<Either<Failure, List<Post>>> execute(GetPostsParams params) {
    return repository.getPosts(params.followingIds);
  }
}

