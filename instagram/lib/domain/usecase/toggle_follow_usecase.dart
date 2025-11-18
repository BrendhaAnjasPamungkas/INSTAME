import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

class ToggleFollowParams {
  final String targetUserId;
  final String currentUserId;

  ToggleFollowParams({required this.targetUserId, required this.currentUserId});
}

class ToggleFollowUseCase implements UseCase<void, ToggleFollowParams> {
  final AuthRepository repository;

  ToggleFollowUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleFollowParams params) async {
    return await repository.toggleFollowUser(params.targetUserId, params.currentUserId);
  }
}