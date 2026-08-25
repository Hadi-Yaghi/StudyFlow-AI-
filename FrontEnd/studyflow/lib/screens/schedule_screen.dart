import 'package:flutter/material.dart';
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() {
    return _ScheduleScreenState();
  }
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedIndex =0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Text("hello")
    );
  }
}