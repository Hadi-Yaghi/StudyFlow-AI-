class ApiConfig {
  // Base URL for backend server
  // Use 10.0.2.2 for Android Emulator, localhost for Desktop/Web/iOS, or your PC IP
  static String baseUrl = 'http://192.168.10.106:8081';

  // Auth endpoints
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';
  static String get googleAuthUrl => '$baseUrl/api/auth/google';

  // Google OAuth Server Client ID (Web Client ID used as serverClientId for backend token verification)
  static const String googleServerClientId =
      '864921972454-bs6t9sn5kqr2fivi0mm6esrgpqe0cvp3.apps.googleusercontent.com';

  static String get verifyEmailUrl => '$baseUrl/api/auth/verify-email';
  static String get resendVerificationUrl => '$baseUrl/api/auth/resend-verification';
  static String get forgotPasswordUrl => '$baseUrl/api/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/api/auth/reset-password';

  // User & Settings endpoints
  static String get userProfileUrl => '$baseUrl/api/users/me';
  static String get userPasswordUrl => '$baseUrl/api/users/me/password';
  static String get userSettingsUrl => '$baseUrl/api/user-settings';

  // Semesters & Courses endpoints
  static String get semestersUrl => '$baseUrl/api/semesters';
  static String get coursesUrl => '$baseUrl/api/courses';

  // Tasks endpoints
  static String get tasksUrl => '$baseUrl/api/tasks';
  static String taskItemUrl(int taskId) => '$baseUrl/api/tasks/$taskId';
  static String getCourseTasksUrl(int courseId) => '$baseUrl/api/tasks/course/$courseId';
  static String updateTaskStatusUrl(int taskId) => '$baseUrl/api/tasks/$taskId/status';

  // Study Sessions endpoints
  static String get studySessionsUrl => '$baseUrl/api/study-sessions';
  static String get studySessionDatesUrl => '$baseUrl/api/study-sessions/dates';
  static String getTaskSessionsUrl(int taskId) => '$baseUrl/api/study-sessions/task/$taskId';
  static String getCourseSessionsUrl(int courseId) => '$baseUrl/api/study-sessions/course/$courseId';
  static String updateSessionStatusUrl(int sessionId) => '$baseUrl/api/study-sessions/$sessionId/status';

  // Scheduler endpoint
  static String get generateScheduleUrl => '$baseUrl/api/scheduler/generate';

  // Availability endpoint
  static String get availabilityUrl => '$baseUrl/api/availability';

  // Study Preferences endpoint
  static String get preferencesUrl => '$baseUrl/api/study-preferences';

  // Subscription endpoints
  static String get subscriptionStatusUrl => '$baseUrl/api/subscription/status';
  static String get subscriptionSyncUrl => '$baseUrl/api/subscription/sync';

  // Schedule Usage endpoint
  static String get scheduleUsageUrl => '$baseUrl/api/scheduler/usage';

  // Course Materials endpoints
  static String getCourseMaterialsUrl(int courseId) => '$baseUrl/api/courses/$courseId/materials';
  static String getCourseMaterialDownloadUrl(int courseId, int materialId) => '$baseUrl/api/courses/$courseId/materials/$materialId/download';
  static String getCourseMaterialDeleteUrl(int courseId, int materialId) => '$baseUrl/api/courses/$courseId/materials/$materialId';

  // AI Study Plan endpoint
  static String getAiPlanUrl(int courseId) => '$baseUrl/api/ai/courses/$courseId/plan';
}
