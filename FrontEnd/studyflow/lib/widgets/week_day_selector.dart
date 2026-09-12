import 'package:flutter/material.dart';

class WeekDaySelector extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime>? onDateSelected;

  const WeekDaySelector({
    super.key,
    this.initialDate,
    this.onDateSelected,
  });

  @override
  State<WeekDaySelector> createState() => _WeekDaySelectorState();
}

class _WeekDaySelectorState extends State<WeekDaySelector> {
  final DateTime today = DateTime.now();

  late DateTime selectedMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
    selectedMonth = DateTime(selectedDate.year, selectedDate.month);
  }

  final List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );

      selectedDate = DateTime(
        selectedMonth.year,
        selectedMonth.month,
        1,
      );
    });
    widget.onDateSelected?.call(selectedDate);
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );

      selectedDate = DateTime(
        selectedMonth.year,
        selectedMonth.month,
        1,
      );
    });
    widget.onDateSelected?.call(selectedDate);
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    return Column(
      children: [
        // Month selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),

            Text(
              '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            IconButton(
              onPressed: nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Date slider
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final DateTime date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                index + 1,
              );

              final bool isSelected = isSameDay(
                date,
                selectedDate,
              );

              final bool isToday = isSameDay(
                date,
                today,
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                  widget.onDateSelected?.call(date);
                },
                child: Container(
                  width: 65,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3525CD)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3525CD)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNames[date.weekday - 1],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF464555),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF252631),
                        ),
                      ),

                      if (isToday && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3525CD),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}