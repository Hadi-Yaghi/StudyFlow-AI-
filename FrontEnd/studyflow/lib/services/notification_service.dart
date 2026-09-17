import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/study_session_model.dart';
import '../models/task_model.dart';
import 'schedule_service.dart';
import 'task_service.dart';
import 'user_settings_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ScheduleService _scheduleService = ScheduleService();
  final TaskService _taskService = TaskService();
  final UserSettingsService _userSettingsService = UserSettingsService();

  bool _isInitialized = false;

  // Notification Channel IDs
  static const String _sessionRemindersChannelId = 'study_session_reminders';
  static const String _sessionRemindersChannelName = 'Study Reminders';
  static const String _sessionRemindersChannelDesc = 'Reminders before scheduled study sessions and session start times';

  static const String _taskDeadlinesChannelId = 'task_deadlines';
  static const String _taskDeadlinesChannelName = 'Task Deadlines';
  static const String _taskDeadlinesChannelDesc = 'Reminders for upcoming academic task deadlines';

  static const String _scheduleUpdatesChannelId = 'schedule_updates';
  static const String _scheduleUpdatesChannelName = 'Schedule Updates';
  static const String _scheduleUpdatesChannelDesc = 'Notifications for missed and rescheduled study sessions';

  /// Deterministic ID generators to ensure unique, non-overlapping IDs
  int getSessionReminderId(int sessionId) => 1000000 + (sessionId * 2);
  int getSessionStartId(int sessionId) => 1000000 + (sessionId * 2) + 1;
  int getTaskDeadlineId(int taskId) => 2000000 + taskId;
  int getRescheduledAlertId(int sessionId) => 3000000 + sessionId;
  int getMissedAlertId(int sessionId) => 4000000 + sessionId;

  /// Initialize local notifications and device timezone
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone data
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      developer.log('Initialized timezone: $timeZoneName', name: 'NotificationService');

      // 2. Android Initialization Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          developer.log('Notification tapped with payload: ${response.payload}', name: 'NotificationService');
        },
      );

      // 3. Create Android notification channels
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            _sessionRemindersChannelId,
            _sessionRemindersChannelName,
            description: _sessionRemindersChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            _taskDeadlinesChannelId,
            _taskDeadlinesChannelName,
            description: _taskDeadlinesChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            _scheduleUpdatesChannelId,
            _scheduleUpdatesChannelName,
            description: _scheduleUpdatesChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _isInitialized = true;
      developer.log('NotificationService successfully initialized', name: 'NotificationService');
    } catch (e) {
      developer.log('Error initializing NotificationService: $e', name: 'NotificationService');
    }
  }

  /// Request notification permission on Android 13+ (POST_NOTIFICATIONS)
  Future<bool> requestPermission() async {
    try {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_permission_prompted', true);
        developer.log('Notification permission request result: $granted', name: 'NotificationService');
        return granted ?? false;
      }
    } catch (e) {
      developer.log('Error requesting notification permission: $e', name: 'NotificationService');
    }
    return false;
  }

  /// Check whether permission was already prompted once to avoid nagging
  Future<bool> wasPermissionPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_permission_prompted') ?? false;
  }

  /// Schedule notifications for an upcoming PLANNED session:
  /// 1. Reminder 10 minutes before start time
  /// 2. Alert at exact session start time
  Future<void> scheduleSessionNotifications(StudySessionModel session) async {
    if (!_isInitialized) await init();

    if (session.status.toUpperCase() != 'PLANNED') {
      developer.log('Skipping notification for non-planned session ID=${session.id} (status=${session.status})',
          name: 'NotificationService');
      return;
    }

    final sessionDateTime = _parseSessionDateTime(session.sessionDate, session.startTime);
    if (sessionDateTime == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final reminderTime = sessionDateTime.subtract(const Duration(minutes: 10));

    final taskName = session.taskTitle.isNotEmpty ? session.taskTitle : 'Study Session';
    final formattedStartTime = _formatDisplayTime(session.startTime);

    // 1. Schedule 10-minute reminder if in future
    if (reminderTime.isAfter(now)) {
      final reminderId = getSessionReminderId(session.id);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: reminderId,
          title: 'Study session in 10 minutes',
          body: '$taskName starts at $formattedStartTime.',
          scheduledDate: reminderTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _sessionRemindersChannelId,
              _sessionRemindersChannelName,
              channelDescription: _sessionRemindersChannelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'session:${session.id}',
        );
        developer.log('SCHEDULE_NOTIFICATION reminder: ID=$reminderId sessionId=${session.id} at $reminderTime',
            name: 'NotificationService');
      } catch (e) {
        developer.log('Failed to schedule 10-minute reminder for session ID=${session.id}: $e',
            name: 'NotificationService');
      }
    }

    // 2. Schedule Start Reminder if in future
    if (sessionDateTime.isAfter(now)) {
      final startId = getSessionStartId(session.id);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: startId,
          title: "It's time to study",
          body: '$taskName • ${session.plannedMinutes} min',
          scheduledDate: sessionDateTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _sessionRemindersChannelId,
              _sessionRemindersChannelName,
              channelDescription: _sessionRemindersChannelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'session:${session.id}',
        );
        developer.log('SCHEDULE_NOTIFICATION start: ID=$startId sessionId=${session.id} at $sessionDateTime',
            name: 'NotificationService');
      } catch (e) {
        developer.log('Failed to schedule start reminder for session ID=${session.id}: $e',
            name: 'NotificationService');
      }
    }
  }

  /// Schedule a deadline notification 24 hours before a pending task's due date
  Future<void> scheduleTaskDeadlineNotification(TaskModel task) async {
    if (!_isInitialized) await init();

    if (task.status.toUpperCase() == 'COMPLETED' || task.dueDate.isEmpty) {
      return;
    }

    DateTime? dueDate;
    try {
      dueDate = DateTime.parse(task.dueDate);
    } catch (_) {
      return;
    }

    // Target: 09:00 AM device local time 1 day before the due date
    final targetDay = dueDate.subtract(const Duration(days: 1));
    final deadlineNotificationTime = tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      9,
      0,
    );

    final now = tz.TZDateTime.now(tz.local);
    if (!deadlineNotificationTime.isAfter(now)) {
      return;
    }

    final deadlineId = getTaskDeadlineId(task.id);
    try {
      await _notificationsPlugin.zonedSchedule(
        id: deadlineId,
        title: 'Upcoming Task Deadline',
        body: '${task.title} is due tomorrow.',
        scheduledDate: deadlineNotificationTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _taskDeadlinesChannelId,
            _taskDeadlinesChannelName,
            channelDescription: _taskDeadlinesChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task:${task.id}',
      );
      developer.log('SCHEDULE_NOTIFICATION deadline: ID=$deadlineId taskId=${task.id} at $deadlineNotificationTime',
          name: 'NotificationService');
    } catch (e) {
      developer.log('Failed to schedule deadline reminder for task ID=${task.id}: $e',
          name: 'NotificationService');
    }
  }

  /// Cancel all scheduled alarms for a given session (10m reminder + start reminder)
  Future<void> cancelSessionNotifications(int sessionId) async {
    if (!_isInitialized) await init();

    final reminderId = getSessionReminderId(sessionId);
    final startId = getSessionStartId(sessionId);

    await _notificationsPlugin.cancel(id: reminderId);
    await _notificationsPlugin.cancel(id: startId);

    developer.log('CANCEL_NOTIFICATION for sessionId=$sessionId (IDs: $reminderId, $startId)',
        name: 'NotificationService');
  }

  /// Cancel deadline alarm for a given task
  Future<void> cancelTaskNotification(int taskId) async {
    if (!_isInitialized) await init();

    final deadlineId = getTaskDeadlineId(taskId);
    await _notificationsPlugin.cancel(id: deadlineId);

    developer.log('CANCEL_NOTIFICATION for taskId=$taskId (ID: $deadlineId)',
        name: 'NotificationService');
  }

  /// Show an immediate alert when a missed session is successfully rescheduled
  Future<void> showRescheduledNotification({
    required int sessionId,
    required String taskTitle,
    required String newDate,
    required String newStartTime,
  }) async {
    if (!_isInitialized) await init();

    final alertId = getRescheduledAlertId(sessionId);
    final displayTime = _formatDisplayTime(newStartTime);
    String displayDate = newDate;
    try {
      final parsed = DateTime.parse(newDate);
      displayDate = DateFormat('EEEE, MMM d').format(parsed);
    } catch (_) {}

    await _notificationsPlugin.show(
      id: alertId,
      title: 'Study session rescheduled',
      body: '$taskTitle was rescheduled to $displayDate at $displayTime.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _scheduleUpdatesChannelId,
          _scheduleUpdatesChannelName,
          channelDescription: _scheduleUpdatesChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'session:$sessionId',
    );
  }

  /// Show an immediate alert when a session was missed
  Future<void> showMissedNotification({
    required int sessionId,
    required String taskTitle,
  }) async {
    if (!_isInitialized) await init();

    final alertId = getMissedAlertId(sessionId);
    await _notificationsPlugin.show(
      id: alertId,
      title: 'Session missed',
      body: 'You missed your $taskTitle study session.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _scheduleUpdatesChannelId,
          _scheduleUpdatesChannelName,
          channelDescription: _scheduleUpdatesChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'missed:$sessionId',
    );
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) await init();
    await _notificationsPlugin.cancelAll();
    developer.log('CANCEL_ALL_NOTIFICATIONS called', name: 'NotificationService');
  }

  /// Authoritative synchronization against the backend database truth
  /// Checks user preferences, loads future PLANNED sessions and pending tasks,
  /// updating device alarms accordingly.
  Future<void> syncNotificationsWithDatabase() async {
    if (!_isInitialized) await init();

    developer.log('Starting syncNotificationsWithDatabase...', name: 'NotificationService');

    try {
      final settings = await _userSettingsService.getSettings();
      final bool notificationsEnabled = settings['notificationsEnabled'] == true;
      final bool studyReminders = settings['studyReminders'] == true;
      final bool taskDeadlines = settings['taskDeadlines'] == true;

      if (!notificationsEnabled) {
        developer.log('Notifications disabled in settings. Cancelling all notifications.',
            name: 'NotificationService');
        await cancelAll();
        return;
      }

      // 1. Sync study session reminders across the next 7 candidate days
      if (studyReminders) {
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final candidateDate = now.plusDays(i);
          try {
            final sessions = await _scheduleService.getSessionsByDate(candidateDate);
            for (final session in sessions) {
              if (session.status.toUpperCase() == 'PLANNED') {
                await scheduleSessionNotifications(session);
              } else {
                // Obsolete / completed / missed: ensure cancelled
                await cancelSessionNotifications(session.id);
              }
            }
          } catch (e) {
            developer.log('Failed fetching sessions for date $candidateDate during sync: $e',
                name: 'NotificationService');
          }
        }
      } else {
        developer.log('studyReminders disabled in settings. Skipping session notifications.',
            name: 'NotificationService');
      }

      // 2. Sync task deadline reminders
      if (taskDeadlines) {
        try {
          final tasks = await _taskService.getTasks();
          for (final task in tasks) {
            if (task.status.toUpperCase() == 'COMPLETED') {
              await cancelTaskNotification(task.id);
            } else {
              await scheduleTaskDeadlineNotification(task);
            }
          }
        } catch (e) {
          developer.log('Failed fetching tasks during sync: $e', name: 'NotificationService');
        }
      } else {
        developer.log('taskDeadlines disabled in settings. Skipping deadline notifications.',
            name: 'NotificationService');
      }

      developer.log('Finished syncNotificationsWithDatabase successfully', name: 'NotificationService');
    } catch (e) {
      developer.log('Error during syncNotificationsWithDatabase: $e', name: 'NotificationService');
    }
  }

  tz.TZDateTime? _parseSessionDateTime(String sessionDate, String startTime) {
    if (sessionDate.isEmpty || startTime.isEmpty) return null;
    try {
      final dateParts = sessionDate.split('-').map(int.parse).toList();
      final timeParts = startTime.split(':').map(int.parse).toList();

      return tz.TZDateTime(
        tz.local,
        dateParts[0],
        dateParts[1],
        dateParts[2],
        timeParts[0],
        timeParts[1],
      );
    } catch (e) {
      developer.log('Failed parsing date/time "$sessionDate $startTime": $e', name: 'NotificationService');
      return null;
    }
  }

  String _formatDisplayTime(String rawTime) {
    if (rawTime.isEmpty) return '';
    try {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1].padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$displayHour:$minute $period';
      }
    } catch (_) {}
    return rawTime;
  }
}

extension DateTimeDays on DateTime {
  DateTime plusDays(int days) {
    return add(Duration(days: days));
  }
}
