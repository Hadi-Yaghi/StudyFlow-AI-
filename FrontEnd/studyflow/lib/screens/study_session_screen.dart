import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../widgets/session_timer.dart';
import '../services/ad_service.dart';

class StudySessionScreen extends StatefulWidget {
  final int? sessionId;
  final int? plannedMinutes;
  final String courseTitle;
  final String sessionTitle;
  final String timeInfo;

  const StudySessionScreen({
    this.sessionId,
    this.plannedMinutes,
    this.courseTitle = "Database Systems",
    this.sessionTitle = "ER Diagram Assignment",
    this.timeInfo = "18:00 - 19:30 (90 min)",
    super.key,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  Timer? _timer;
  late int _secondsRemaining;
  late int _totalSeconds;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final minutes = widget.plannedMinutes ?? 90;
    _secondsRemaining = minutes * 60;
    _totalSeconds = _secondsRemaining;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });

      // Update session status to IN_PROGRESS on start
      if (widget.sessionId != null) {
        ScheduleService().updateSessionStatus(widget.sessionId!, 'IN_PROGRESS', 0);
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
          });

          // Mark completed and cancel obsolete notification
          if (widget.sessionId != null) {
            ScheduleService().updateSessionStatus(widget.sessionId!, 'COMPLETED', widget.plannedMinutes ?? 60);
            NotificationService.instance.cancelSessionNotifications(widget.sessionId!);
          }

          AdService.instance.showInterstitialIfEligible(actionContext: 'study_session_completed');
        }
      });
    }
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _totalSeconds > 0 ? (_secondsRemaining / _totalSeconds).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Close X on left, Centered StudyFlow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 26,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Course Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEECFE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 16,
                            color: Color(0xFF3525CD),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.courseTitle,
                            style: const TextStyle(
                              color: Color(0xFF3525CD),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Large Session Title
                    Text(
                      widget.sessionTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Time Information
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.timeInfo,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    // Reusable Session Timer UI
                    SessionTimer(
                      displayTime: _formattedTime,
                      progress: progress,
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),

            // Bottom Full Width Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3525CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _toggleTimer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning ? "PAUSE SESSION" : "START SESSION",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
