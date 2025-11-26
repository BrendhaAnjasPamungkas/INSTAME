import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

class GetAuthStatusUsecase {
  final AuthRepository repository;
  GetAuthStatusUsecase (this.repository);
  Stream<User?>execute(){
    return repository.authStateChanges;
  }
}