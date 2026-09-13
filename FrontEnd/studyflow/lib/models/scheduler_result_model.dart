class SchedulerResultModel {
  final int generatedSessions;
  final int scheduledMinutes;
  final int unscheduledMinutes;
  final String? firstSessionDate;
  final List<String> sessionDates;
  final String? status;
  final String? message;
  final String? failureReason;

  SchedulerResultModel({
    required this.generatedSessions,
    required this.scheduledMinutes,
    required this.unscheduledMinutes,
    this.firstSessionDate,
    required this.sessionDates,
    this.status,
    this.message,
    this.failureReason,
  });

  factory SchedulerResultModel.fromJson(Map<String, dynamic> json) {
    List<String> dates = [];
    if (json['sessionDates'] is List) {
      dates = (json['sessionDates'] as List)
          .map((d) => d.toString())
          .toList();
    }

    return SchedulerResultModel(
      generatedSessions: json['generatedSessions'] is int
          ? json['generatedSessions']
          : int.tryParse(json['generatedSessions']?.toString() ?? '') ?? 0,
      scheduledMinutes: json['scheduledMinutes'] is int
          ? json['scheduledMinutes']
          : int.tryParse(json['scheduledMinutes']?.toString() ?? '') ?? 0,
      unscheduledMinutes: json['unscheduledMinutes'] is int
          ? json['unscheduledMinutes']
          : int.tryParse(json['unscheduledMinutes']?.toString() ?? '') ?? 0,
      firstSessionDate: json['firstSessionDate']?.toString(),
      sessionDates: dates,
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      failureReason: json['failureReason']?.toString(),
    );
  }
}
