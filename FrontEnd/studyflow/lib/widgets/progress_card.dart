import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int completedSessions;
  final int totalSessions;
  final int completedMinutes;
  final int totalMinutes;
  final double progressPercent;

  const ProgressCard({
    this.completedSessions = 0,
    this.totalSessions = 0,
    this.completedMinutes = 0,
    this.totalMinutes = 0,
    this.progressPercent = 0.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double safeProgress = progressPercent.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    value: totalSessions > 0 ? safeProgress : 0.0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(53, 37, 205, 1),
                    ),
                  ),
                ),

                const SizedBox(width: 25),

                const Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$completedSessions/$totalSessions sessions completed"),
                    Text(
                      "$completedMinutes/$totalMinutes min",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(53, 37, 205, 1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                LinearProgressIndicator(
                  value: totalSessions > 0 ? safeProgress : 0.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(53, 37, 205, 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}