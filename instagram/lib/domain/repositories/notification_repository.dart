import 'package:dartz/dartz.dart';
import 'package:instagram/core/errors/failures.dart';
import 'package:instagram/domain/entities/notification.dart';

abstract class NotificationRepository {
  Stream<Either<Failure, List<NotificationEntity>>> getNotifications(String userId);
}