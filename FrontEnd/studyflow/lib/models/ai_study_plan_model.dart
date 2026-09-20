class AiTopicRecommendation {
  final String title;
  final int estimatedMinutes;
  final String priority;
  final String? suggestedDeadline;
  final int? sourceMaterialId;
  final List<String> keyConcepts;

  AiTopicRecommendation({
    required this.title,
    required this.estimatedMinutes,
    required this.priority,
    this.suggestedDeadline,
    this.sourceMaterialId,
    required this.keyConcepts,
  });

  factory AiTopicRecommendation.fromJson(Map<String, dynamic> json) {
    return AiTopicRecommendation(
      title: json['title'] as String? ?? 'Untitled Topic',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 60,
      priority: json['priority'] as String? ?? 'MEDIUM',
      suggestedDeadline: json['suggestedDeadline'] as String?,
      sourceMaterialId: json['sourceMaterialId'] as int?,
      keyConcepts: (json['keyConcepts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'estimatedMinutes': estimatedMinutes,
      'priority': priority,
      'suggestedDeadline': suggestedDeadline,
      'sourceMaterialId': sourceMaterialId,
      'keyConcepts': keyConcepts,
    };
  }
}

class AiStudyPlan {
  final int courseId;
  final String courseName;
  final String summary;
  final List<AiTopicRecommendation> topics;
  final int generatedSessionsCount;
  final int scheduledMinutes;
  final List<String> sessionDates;
  final bool successful;
  final String message;

  AiStudyPlan({
    required this.courseId,
    required this.courseName,
    required this.summary,
    required this.topics,
    required this.generatedSessionsCount,
    required this.scheduledMinutes,
    required this.sessionDates,
    required this.successful,
    required this.message,
  });

  factory AiStudyPlan.fromJson(Map<String, dynamic> json) {
    return AiStudyPlan(
      courseId: json['courseId'] as int? ?? 0,
      courseName: json['courseName'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => AiTopicRecommendation.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      generatedSessionsCount: json['generatedSessionsCount'] as int? ?? 0,
      scheduledMinutes: json['scheduledMinutes'] as int? ?? 0,
      sessionDates: (json['sessionDates'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
      successful: json['successful'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
