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
      id: json['id'] ?? 0,
      sessionDate: json['sessionDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      plannedMinutes: json['plannedMinutes'] ?? 0,
      completedMinutes: json['completedMinutes'] ?? 0,
      status: json['status'] ?? 'PLANNED',
      taskId: json['taskId'] ?? 0,
      taskTitle: json['taskTitle'] ?? '',
    );
  }
}
