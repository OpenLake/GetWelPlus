import 'package:flutter/material.dart';

/// Notification service is intentionally stubbed out because the project is
/// using a platform plugin that may fail on dependency compatibility (android
/// namespace build issue with flutter_local_notifications). These methods are
/// safe noops so the app still starts.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    debugPrint('NotificationService.initialize no-op (notifications disabled).');
  }

  Future<void> requestPermissions() async {
    debugPrint('NotificationService.requestPermissions no-op.');
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required String payload,
    int hour = 20,
    int minute = 0,
  }) async {
    debugPrint('scheduleDailyReminder id=$id title=$title');
  }

  Future<void> cancel(int id) async {
    debugPrint('cancel notification id=$id');
  }

  Future<void> cancelAll() async {
    debugPrint('cancel all notifications');
  }
}

