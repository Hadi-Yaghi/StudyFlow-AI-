import 'package:flutter/material.dart';

class SessionTimer extends StatelessWidget {
  final String displayTime; // e.g. "90:00"
  final double progress; // 0.0 to 1.0

  const SessionTimer({
    required this.displayTime,
    this.progress = 1.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background grey circle
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3525CD),
              ),
            ),
          ),
          // Inner text content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayTime,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "REMAINING",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
