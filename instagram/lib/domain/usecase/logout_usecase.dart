import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/core/usecase/usecase.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

class LogOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.logOut();
  }
}