import 'package:flutter/material.dart';
import '../models/availability_model.dart';
import '../services/availability_service.dart';
import '../widgets/availability_day_item.dart';

class DayAvailability {
  final String dayName;
  bool isEnabled;
  TimeOfDay startTime;
  TimeOfDay endTime;

  DayAvailability({
    required this.dayName,
    required this.isEnabled,
    required this.startTime,
    required this.endTime,
  });
}

class AvailabilitySettingsScreen extends StatefulWidget {
  const AvailabilitySettingsScreen({super.key});

  @override
  State<AvailabilitySettingsScreen> createState() => _AvailabilitySettingsScreenState();
}

class _AvailabilitySettingsScreenState extends State<AvailabilitySettingsScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  bool _isSaving = false;

  final List<DayAvailability> _days = [
    DayAvailability(
      dayName: "Monday",
      isEnabled: true,
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 22, minute: 0),
    ),
    DayAvailability(
      dayName: "Tuesday",
      isEnabled: true,
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 22, minute: 0),
    ),
    DayAvailability(
      dayName: "Wednesday",
      isEnabled: false,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
    ),
    DayAvailability(
      dayName: "Thursday",
      isEnabled: true,
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 22, minute: 0),
    ),
    DayAvailability(
      dayName: "Friday",
      isEnabled: true,
      startTime: const TimeOfDay(hour: 17, minute: 0),
      endTime: const TimeOfDay(hour: 21, minute: 0),
    ),
    DayAvailability(
      dayName: "Saturday",
      isEnabled: true,
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayName: "Sunday",
      isEnabled: true,
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final list = await _availabilityService.getUserAvailability();
      if (list.isNotEmpty && mounted) {
        setState(() {
          for (final item in list) {
            final dayIndex = _days.indexWhere(
              (d) => d.dayName.toUpperCase() == item.day.toUpperCase(),
            );
            if (dayIndex != -1) {
              _days[dayIndex].isEnabled = item.enabled;
              final startParts = item.startTime.split(':');
              if (startParts.length >= 2) {
                _days[dayIndex].startTime = TimeOfDay(
                  hour: int.tryParse(startParts[0]) ?? 18,
                  minute: int.tryParse(startParts[1]) ?? 0,
                );
              }
              final endParts = item.endTime.split(':');
              if (endParts.length >= 2) {
                _days[dayIndex].endTime = TimeOfDay(
                  hour: int.tryParse(endParts[0]) ?? 22,
                  minute: int.tryParse(endParts[1]) ?? 0,
                );
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isSaving = true;
    });

    try {
      for (final day in _days) {
        final start = "${day.startTime.hour.toString().padLeft(2, '0')}:${day.startTime.minute.toString().padLeft(2, '0')}:00";
        final end = "${day.endTime.hour.toString().padLeft(2, '0')}:${day.endTime.minute.toString().padLeft(2, '0')}:00";

        final model = AvailabilityModel(
          day: day.dayName.toUpperCase(),
          startTime: start,
          endTime: end,
          enabled: day.isEnabled,
        );
        await _availabilityService.saveAvailability(model);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Availability settings saved successfully!"),
            backgroundColor: Color(0xFF3525CD),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save availability: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _pickTime(int index, bool isStartTime) async {
    final day = _days[index];
    final initial = isStartTime ? day.startTime : day.endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          day.startTime = picked;
        } else {
          day.endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar: Back arrow, Centered StudyFlow, Right Bell
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1F2937),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: Color(0xFF1F2937),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Text(
                    "StudyFlow",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3525CD),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      "Availability Settings",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      "Manage when you are available for study sessions and notifications.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Days Availability White Card Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(_days.length, (index) {
                          final day = _days[index];
                          return AvailabilityDayItem(
                            dayName: day.dayName,
                            isEnabled: day.isEnabled,
                            startTime: _formatTime(day.startTime),
                            endTime: _formatTime(day.endTime),
                            showDivider: index < _days.length - 1,
                            onToggleChanged: (val) {
                              setState(() {
                                day.isEnabled = val;
                              });
                            },
                            onSelectStartTime: () => _pickTime(index, true),
                            onSelectEndTime: () => _pickTime(index, false),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3525CD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveAvailability,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isSaving ? "Saving..." : "Save Availability",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
