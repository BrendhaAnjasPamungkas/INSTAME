import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/data/datasources/notification_datasource.dart';
import 'package:instagram/domain/entities/notification.dart';
import 'package:instagram/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<NotificationEntity>>> getNotifications(String userId) {
    return remoteDataSource.getNotifications(userId).map((notifs) {
      return Right<Failure, List<NotificationEntity>>(notifs);
    }).handleError((error) {
      return Left<Failure, List<NotificationEntity>>(ServerFailure(error.toString()));
    });
  }
}