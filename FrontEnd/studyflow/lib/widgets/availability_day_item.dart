import 'package:flutter/material.dart';

class AvailabilityDayItem extends StatelessWidget {
  final String dayName;
  final bool isEnabled;
  final String startTime;
  final String endTime;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onSelectStartTime;
  final VoidCallback onSelectEndTime;
  final bool showDivider;

  const AvailabilityDayItem({
    required this.dayName,
    required this.isEnabled,
    required this.startTime,
    required this.endTime,
    required this.onToggleChanged,
    required this.onSelectStartTime,
    required this.onSelectEndTime,
    this.showDivider = true,
    super.key,
  });

  Widget _buildTimeButton({
    required String time,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? const Color(0xFF1F2937) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Day Name & Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isEnabled ? const Color(0xFF111827) : Colors.grey.shade600,
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      activeTrackColor: const Color(0xFF3525CD),
                      onChanged: onToggleChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Time Selection Row
                Row(
                  children: [
                    _buildTimeButton(
                      time: startTime,
                      onTap: onSelectStartTime,
                      enabled: isEnabled,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "-",
                        style: TextStyle(
                          fontSize: 16,
                          color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    _buildTimeButton(
                      time: endTime,
                      onTap: onSelectEndTime,
                      enabled: isEnabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade200,
            ),
        ],
      ),
    );
  }
}
