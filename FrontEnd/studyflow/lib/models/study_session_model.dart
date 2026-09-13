class StudySessionModel {
  final int id;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final int plannedMinutes;
  final int completedMinutes;
  final String status; // PLANNED, IN_PROGRESS, COMPLETED, MISSED
  final int taskId;
  final String taskTitle;

  StudySessionModel({
    required this.id,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.status,
    required this.taskId,
    required this.taskTitle,
  });

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      sessionDate: json['sessionDate']?.toString() ?? '',
      startTime: _parseTime(json['startTime']),
      endTime: _parseTime(json['endTime']),
      plannedMinutes: json['plannedMinutes'] is int
          ? json['plannedMinutes']
          : int.tryParse(json['plannedMinutes']?.toString() ?? '') ?? 0,
      completedMinutes: json['completedMinutes'] is int
          ? json['completedMinutes']
          : int.tryParse(json['completedMinutes']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'PLANNED',
      taskId: json['taskId'] is int
          ? json['taskId']
          : int.tryParse(json['taskId']?.toString() ?? '') ?? 0,
      taskTitle: json['taskTitle']?.toString() ?? '',
    );
  }

  static String _parseTime(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      final h = value[0].toString().padLeft(2, '0');
      final m = value.length > 1 ? value[1].toString().padLeft(2, '0') : '00';
      final s = value.length > 2 ? ":${value[2].toString().padLeft(2, '0')}" : '';
      return '$h:$m$s';
    }
    return value.toString();
  }
}
