class StudyPreferencesModel {
  final int maxSessionMinutes;
  final int breakMinutes;
  final bool allowWeekendStudy;
  final String preferredStudyStart;
  final String preferredStudyEnd;

  StudyPreferencesModel({
    required this.maxSessionMinutes,
    required this.breakMinutes,
    required this.allowWeekendStudy,
    required this.preferredStudyStart,
    required this.preferredStudyEnd,
  });

  factory StudyPreferencesModel.fromJson(Map<String, dynamic> json) {
    return StudyPreferencesModel(
      maxSessionMinutes: json['maxSessionMinutes'] ?? 45,
      breakMinutes: json['breakMinutes'] ?? 10,
      allowWeekendStudy: json['allowWeekendStudy'] ?? true,
      preferredStudyStart: json['preferredStudyStart'] ?? '09:00:00',
      preferredStudyEnd: json['preferredStudyEnd'] ?? '22:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxSessionMinutes': maxSessionMinutes,
      'breakMinutes': breakMinutes,
      'allowWeekendStudy': allowWeekendStudy,
      'preferredStudyStart': preferredStudyStart,
      'preferredStudyEnd': preferredStudyEnd,
    };
  }
}
