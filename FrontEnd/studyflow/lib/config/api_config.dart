class ApiConfig {
  // Base URL for backend server
  // Use 10.0.2.2 for Android Emulator, localhost for Desktop/Web/iOS, or your PC IP
  static String baseUrl = 'http://192.168.0.102:8081';

  // Auth endpoints
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';

  // Semesters & Courses endpoints
  static String get semestersUrl => '$baseUrl/api/semesters';
  static String get coursesUrl => '$baseUrl/api/courses';

  // Tasks endpoints
  static String get tasksUrl => '$baseUrl/api/tasks';

  // Study Sessions endpoints
  static String get studySessionsUrl => '$baseUrl/api/study-sessions';
  static String getTaskSessionsUrl(int taskId) => '$baseUrl/api/study-sessions/task/$taskId';
  static String updateSessionStatusUrl(int sessionId) => '$baseUrl/api/study-sessions/$sessionId/status';

  // Scheduler endpoint
  static String get generateScheduleUrl => '$baseUrl/api/scheduler/generate';

  // Availability endpoint
  static String get availabilityUrl => '$baseUrl/api/availability';

  // Study Preferences endpoint
  static String get preferencesUrl => '$baseUrl/api/study-preferences';
}
