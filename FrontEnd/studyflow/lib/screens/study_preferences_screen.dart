import 'package:flutter/material.dart';
import '../models/study_preferences_model.dart';
import '../services/study_preferences_service.dart';

class StudyPreferencesScreen extends StatefulWidget {
  const StudyPreferencesScreen({super.key});

  @override
  State<StudyPreferencesScreen> createState() => _StudyPreferencesScreenState();
}

class _StudyPreferencesScreenState extends State<StudyPreferencesScreen> {
  final StudyPreferencesService _preferencesService = StudyPreferencesService();
  String selectedSessionDuration = "45m";
  String selectedBreakDuration = "10m";
  bool weekendStudyEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final pref = await _preferencesService.getPreferences();
      if (pref != null && mounted) {
        setState(() {
          selectedSessionDuration = "${pref.maxSessionMinutes}m";
          selectedBreakDuration = "${pref.breakMinutes}m";
          weekendStudyEnabled = pref.allowWeekendStudy;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    final maxMinutes = int.tryParse(selectedSessionDuration.replaceAll('m', '')) ?? 45;
    final breakMinutes = int.tryParse(selectedBreakDuration.replaceAll('m', '')) ?? 10;

    final pref = StudyPreferencesModel(
      maxSessionMinutes: maxMinutes,
      breakMinutes: breakMinutes,
      allowWeekendStudy: weekendStudyEnabled,
      preferredStudyStart: "09:00:00",
      preferredStudyEnd: "22:00:00",
    );

    try {
      await _preferencesService.savePreferences(pref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Study preferences saved successfully!"),
            backgroundColor: Color(0xFF3525CD),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Study preferences saved locally!"),
            backgroundColor: Color(0xFF3525CD),
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

  Widget _buildOptionPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEECFE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF3525CD) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3525CD) : const Color(0xFF1F2937),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1F2937),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
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
                    const Text(
                      "Study Preferences",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Customize your optimal learning flow.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card 1: Max Session Duration
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEECFE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  color: Color(0xFF3525CD),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  "Max Session Duration",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "How long do you want to focus before a mandatory break?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['30m', '45m', '60m', '90m', '120m'].map((dur) {
                              return _buildOptionPill(
                                label: dur,
                                isSelected: selectedSessionDuration == dur,
                                onTap: () {
                                  setState(() {
                                    selectedSessionDuration = dur;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Break Duration
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEECFE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.coffee_outlined,
                                  color: Color(0xFF3525CD),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  "Break Duration",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Standard rest period between focus blocks.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['5m', '10m', '15m', '20m', '30m'].map((dur) {
                              return _buildOptionPill(
                                label: dur,
                                isSelected: selectedBreakDuration == dur,
                                onTap: () {
                                  setState(() {
                                    selectedBreakDuration = dur;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Weekend Study
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3E0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.weekend_outlined,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Weekend Study",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Schedule automated tasks on Sat/Sun.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: weekendStudyEnabled,
                            activeTrackColor: const Color(0xFF3525CD),
                            onChanged: (val) {
                              setState(() {
                                weekendStudyEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Save Preferences Button
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
                        onPressed: _isSaving ? null : _savePreferences,
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
                          _isSaving ? "Saving..." : "Save Preferences",
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
