import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/data/datasources/auth_datasources.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/repositories/auth_repository.dart';

// import 'package.my_insta_clone/core/platform/network_info.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;
  // final NetworkInfo networkInfo; // TODO: Tambahkan ini nanti

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
    // required this.networkInfo,
  });
  @override
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  @override
  Future<Either<Failure, UserEntity>> signIn(
    String email,
    String password,
  ) async {
    // if (await networkInfo.isConnected) { // TODO: Cek koneksi nanti
    try {
      // 1. Login via Firebase Auth
      final userCredential = await remoteDataSource.signIn(email, password);

      // 2. Auth berhasil, TAPI kita butuh data dari Firestore (username, dll)
      // Kita panggil metode 'getUser' yang akan kita buat di data source
      final userModel = await remoteDataSource.getUser(
        userCredential.user!.uid,
      );
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure("Login Gagal: ${e.message}"));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
  @override
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query) async {
    try {
      final userModels = await remoteDataSource.searchUsers(query);
      return Right(userModels); // UserModel adalah UserEntity
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  

  @override
  Future<Either<Failure, UserEntity>> signUp(
    String username,
    String fullName,
    String email,
    String password,
  ) async {
    try {
      // Panggil data source
      final userModel = await remoteDataSource.signUp(
        username,
        fullName,
        email,
        password,
      );
      // UserModel adalah UserEntity, jadi ini valid
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure("Daftar Gagal: ${e.message}"));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
@override
  Future<Either<Failure, UserEntity>> getUserData(String uid) async {
    // Kita panggil fungsi 'getUser' yang sudah ada di datasource
    try {
      final userModel = await remoteDataSource.getUser(uid);
      return Right(userModel);
    } on ServerException catch (e) { // <-- Menangkap error server
      return Left(ServerFailure(e.message));
    } catch (e) { // <-- INI AKAN MENANGKAP 'TypeError'
      return Left(ServerFailure("Gagal memproses data user: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await remoteDataSource.logOut();
      return Right(null); // Sukses (void)
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure("Gagal Log Out: ${e.message}"));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFollowUser(
    String targetUserId,
    String currentUserId,
  ) async {
    try {
      await remoteDataSource.toggleFollowUser(targetUserId, currentUserId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
  @override
  Future<Either<Failure, void>> updateUserData(String uid, String newUsername, String newBio, String? newProfileImageUrl) async {
    try {
      await remoteDataSource.updateUserData(uid, newUsername, newBio, newProfileImageUrl);
      return Right(null); // Sukses (void)
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

}
