import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/post_repositories.dart';

class DeletePostParams {
  final String postId;
  DeletePostParams(this.postId);
}

class DeletePostUseCase implements UseCase<void, DeletePostParams> {
  final PostRepository repository;

  DeletePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePostParams params) async {
    return await repository.deletePost(params.postId);
  }
}