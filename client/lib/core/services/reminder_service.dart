import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// System-level background notification and alarm scheduler for ENX Money
/// Ensures EMI, GST, bill, and Khata payment reminders trigger reliably
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[ReminderService] Notification interaction: ${response.payload}');
        },
      );

      _isInitialized = true;

      // Request permissions on Android 13+ (API 33+)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('[ReminderService] Initialization error: $e');
    }
  }

  /// Schedule a precise alarm/notification for a specific future DateTime
  Future<void> scheduleFinancialReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await initialize();

    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        debugPrint('[ReminderService] Scheduled date $scheduledDate is in the past, skipping.');
        return;
      }

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'enx_money_reminders_channel',
        'Financial & EMI Reminders',
        channelDescription:
            'Critical notifications for GST compliance, loan EMIs, and business bills.',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('[ReminderService] Successfully scheduled reminder #$id for $scheduledDate');
    } catch (e) {
      debugPrint('[ReminderService] Error scheduling notification: $e');
    }
  }

  /// Cancel an individual scheduled notification by its integer ID
  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
      debugPrint('[ReminderService] Cancelled reminder #$id');
    } catch (e) {
      debugPrint('[ReminderService] Cancel error: $e');
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[ReminderService] All scheduled reminders cancelled');
    } catch (e) {
      debugPrint('[ReminderService] CancelAll error: $e');
    }
  }
}
