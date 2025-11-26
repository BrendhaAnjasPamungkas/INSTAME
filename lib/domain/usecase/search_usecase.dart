import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

class SearchUsersParams {
  final String query;
  SearchUsersParams(this.query);
}

class SearchUsersUseCase implements UseCase<List<UserEntity>, SearchUsersParams> {
  final AuthRepository repository;

  SearchUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(SearchUsersParams params) async {
    return await repository.searchUsers(params.query);
  }
}