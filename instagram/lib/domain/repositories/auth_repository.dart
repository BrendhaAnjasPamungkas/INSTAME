import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/user.dart'; // OK di domain jika hanya sebagai entitas/tipe data

// Sebenarnya lebih baik membuat entitas User sendiri, tapi untuk
// percepatan, kita bisa pakai User dari Firebase
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp(String username,String fullName,String email, String password);
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  // --- TAMBAHKAN DUA INI ---
  Future<Either<Failure, UserEntity>> getUserData(String uid);
  Future<Either<Failure, void>> logOut();
  Stream<User?> get authStateChanges;
  Future<Either<Failure, void>> toggleFollowUser(String targetUserId, String currentUserId);
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query);
  Future<Either<Failure, void>> updateUserData(String uid, String newUsername, String newBio, String? newProfileImageUrl);
}