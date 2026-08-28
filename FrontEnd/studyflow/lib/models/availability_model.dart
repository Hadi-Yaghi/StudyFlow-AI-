class AvailabilityModel {
  final int? id;
  final String day; // MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
  final String startTime; // "18:00:00"
  final String endTime; // "22:00:00"
  final bool enabled;

  AvailabilityModel({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.enabled,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      id: json['id'],
      day: json['day'] ?? 'MONDAY',
      startTime: json['startTime'] ?? '18:00:00',
      endTime: json['endTime'] ?? '22:00:00',
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'enabled': enabled,
    };
  }
}
