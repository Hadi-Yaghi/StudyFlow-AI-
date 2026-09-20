import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/scheduler_result_model.dart';
import '../models/study_session_model.dart';
import '../services/schedule_service.dart';
import '../widgets/home_header.dart';
import '../widgets/week_day_selector.dart';
import '../widgets/schedule_box.dart';
import 'session_missed_screen.dart';
import 'study_session_screen.dart';
import 'availability_settings_screen.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/feature_access_service.dart';
import '../utils/feature_gate.dart';
import '../widgets/ads/banner_ad_widget.dart';
import 'premium_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  DateTime _selectedDate = DateTime.now();
  List<StudySessionModel> _sessions = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    FeatureGate.access.refreshScheduleUsage();
    FeatureGate.access.addListener(_onFeatureAccessChanged);
  }

  @override
  void dispose() {
    FeatureGate.access.removeListener(_onFeatureAccessChanged);
    super.dispose();
  }

  void _onFeatureAccessChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    final formatted = _formatDate(_selectedDate);
    developer.log('Loading sessions for selected date: $formatted', name: 'ScheduleScreen');

    try {
      final sessions = await _scheduleService.getSessionsByDate(_selectedDate);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
        developer.log('Loaded ${sessions.length} sessions for $formatted', name: 'ScheduleScreen');
        NotificationService.instance.syncNotificationsWithDatabase();
      }
    } catch (e) {
      developer.log('Error loading sessions for $formatted: $e', name: 'ScheduleScreen');
      if (mounted) {
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadSessions();
  }

  Future<void> _handleGenerateSchedule() async {
    if (_isGenerating) return;

    // RULE: Free users are restricted to 3 generations per period
    if (!FeatureGate.access.isPro && FeatureGate.access.remainingFreeScheduleGenerations == 0) {
      FeatureGate.showScheduleLimitReachedDialog(context);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    developer.log('Schedule generation started', name: 'ScheduleScreen');

    SchedulerResultModel? result;
    try {
      result = await _scheduleService.generateSchedule();
      developer.log(
        'Schedule generation succeeded: ${result.generatedSessions} sessions across ${result.sessionDates}',
        name: 'ScheduleScreen',
      );
      // Refresh usage counter
      FeatureGate.access.refreshScheduleUsage();
    } catch (e) {
      developer.log('Schedule generation failed: $e', name: 'ScheduleScreen');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        if (e.toString().contains('SCHEDULE_GENERATION_LIMIT_REACHED')) {
          FeatureGate.showScheduleLimitReachedDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (!mounted) return;

    // Check if 0 sessions were generated
    if (result.generatedSessions == 0) {
      setState(() {
        _isGenerating = false;
      });
      final message = result.message ??
          "No study sessions could be scheduled. Please verify your course tasks and availability.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 5),
          action: result.status == 'NO_AVAILABILITY'
              ? SnackBarAction(
                  label: 'Set Hours',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AvailabilitySettingsScreen(),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
      return;
    }

    // Sessions were generated!
    // Handle selected date: check if the currently selected date has sessions
    final currentFormatted = _formatDate(_selectedDate);
    DateTime targetDate = _selectedDate;

    if (!result.sessionDates.contains(currentFormatted) && result.firstSessionDate != null) {
      try {
        targetDate = DateTime.parse(result.firstSessionDate!);
        developer.log(
          'Current date ($currentFormatted) has no generated sessions. Navigating to first session date: ${result.firstSessionDate}',
          name: 'ScheduleScreen',
        );
      } catch (_) {
        targetDate = _selectedDate;
      }
    }

    setState(() {
      _selectedDate = targetDate;
    });

    // Authoritative reload of sessions for target date
    developer.log('Reloading sessions from backend for date: ${_formatDate(_selectedDate)}', name: 'ScheduleScreen');
    bool refreshFailed = false;
    try {
      final sessions = await _scheduleService.getSessionsByDate(_selectedDate);
      if (mounted) {
        setState(() {
          _sessions = sessions;
        });
        developer.log(
          'Sessions refreshed successfully: ${sessions.length} sessions for ${_formatDate(_selectedDate)}',
          name: 'ScheduleScreen',
        );
      }
    } catch (e) {
      refreshFailed = true;
      developer.log('Refresh failed after generation: $e', name: 'ScheduleScreen');
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      if (refreshFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Schedule generated, but failed to load sessions. Pull down to refresh."),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Schedule generated successfully! (${result.generatedSessions} sessions scheduled)"),
            backgroundColor: const Color(0xFF3525CD),
          ),
        );
        NotificationService.instance.syncNotificationsWithDatabase();
        AdService.instance.showInterstitialIfEligible(actionContext: 'generate_schedule');
      }
    }
  }

  void _navigateToSession(StudySessionModel session) {
    final status = session.status.toLowerCase();
    final timeRange = "${_formatTime(session.startTime)} - ${_formatTime(session.endTime)} (${session.plannedMinutes} min)";

    if (status == 'missed') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SessionMissedScreen(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudySessionScreen(
            sessionId: session.id,
            plannedMinutes: session.plannedMinutes,
            courseTitle: "Task #${session.taskId}",
            sessionTitle: session.taskTitle.isNotEmpty ? session.taskTitle : "Study Session",
            timeInfo: timeRange,
          ),
        ),
      ).then((_) => _loadSessions());
    }
  }

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return "00:00";
    final parts = rawTime.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return "${displayHour.toString().padLeft(2, '0')}:$minute $period";
    }
    return rawTime;
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = (minutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');
      return "${hours}h";
    }
    return "${minutes}m";
  }

  String _formatStatus(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'MISSED':
        return 'Missed';
      case 'PLANNED':
      default:
        return 'Planned';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 25),
                  const Text(
                    "Schedule",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Your academic focus for the week.",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  WeekDaySelector(
                    initialDate: _selectedDate,
                    onDateSelected: _onDateChanged,
                  ),
                  const SizedBox(height: 20),

                  // Loading or Content
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3525CD),
                        ),
                      ),
                    )
                  else if (_sessions.isEmpty)
                    _buildEmptyScheduleState()
                  else ...[
                    ..._sessions.map((session) {
                      final double? progress = session.plannedMinutes > 0 && session.completedMinutes > 0
                          ? (session.completedMinutes / session.plannedMinutes).clamp(0.0, 1.0)
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: ScheduleBox(
                          time: _formatTime(session.startTime),
                          duration: _formatDuration(session.plannedMinutes),
                          subject: session.taskTitle.isNotEmpty ? session.taskTitle : "Task #${session.taskId}",
                          description: "Planned session: ${session.plannedMinutes} min",
                          status: _formatStatus(session.status),
                          progress: progress,
                          onTap: () => _navigateToSession(session),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Free Quota / Pro Indicator
                    _buildQuotaIndicator(),

                    // Generate / Re-generate Schedule Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3525CD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isGenerating ? null : _handleGenerateSchedule,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                              label: Text(
                                _isGenerating ? "Generating..." : "Generate",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFF3525CD).withOpacity(0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _handleGenerateWithAi,
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF3525CD),
                                size: 16,
                              ),
                              label: const Text(
                                "AI Plan",
                                style: TextStyle(
                                  color: Color(0xFF3525CD),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const BannerAdWidget(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Schedule Empty State Layout matching provided design screenshot 1
  Widget _buildEmptyScheduleState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle with calendar_add icon
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            "No study sessions scheduled",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            "Generate a personalized schedule based on your tasks and availability.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Quota indicator in empty state
          _buildQuotaIndicator(),
          const SizedBox(height: 12),

          // Generate Schedule & AI Planner Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3525CD),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isGenerating ? null : _handleGenerateSchedule,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                label: Text(
                  _isGenerating ? "Generating..." : "Generate Schedule",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: BorderSide(color: const Color(0xFF3525CD).withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _handleGenerateWithAi,
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF3525CD),
                  size: 16,
                ),
                label: const Text(
                  "AI Plan",
                  style: TextStyle(
                    color: Color(0xFF3525CD),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildQuotaIndicator() {
    final isPro = FeatureGate.access.isPro;
    final remaining = FeatureGate.access.remainingFreeScheduleGenerations;
    const limit = FeatureAccessService.freeScheduleGenerationLimit;

    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars_rounded, size: 16, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Text(
              "StudyFlow Pro • Unlimited Generations",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      );
    }

    final isExhausted = remaining <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isExhausted ? Colors.red.shade50 : const Color(0xFF3525CD).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExhausted ? Colors.red.shade200 : const Color(0xFF3525CD).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExhausted ? Icons.lock_clock : Icons.refresh_rounded,
            size: 16,
            color: isExhausted ? Colors.red.shade700 : const Color(0xFF3525CD),
          ),
          const SizedBox(width: 8),
          Text(
            isExhausted
                ? "Free quota used (0/$limit remaining)"
                : "Free Generations: $remaining of $limit remaining",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isExhausted ? Colors.red.shade800 : const Color(0xFF3525CD),
            ),
          ),
          if (isExhausted) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Upgrade",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleGenerateWithAi() {
    if (!FeatureGate.access.canGenerateWithAi) {
      FeatureGate.requirePro(
        context,
        onUnlocked: () => _handleGenerateWithAi(),
        featureName: "AI Study Planning",
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF3525CD)),
            SizedBox(width: 10),
            Text("AI Study Planner"),
          ],
        ),
        content: const Text(
          "AI Study Planning analyzes your uploaded course documents (syllabi, slides, notes) to create optimal study plans.\n\nOpen any Course in the Courses tab and tap 'Resources' to upload documents and generate an AI plan.",
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3525CD),
              foregroundColor: Colors.white,
            ),
            child: const Text("Got It"),
          ),
        ],
      ),
    );
  }
}