import 'package:flutter/material.dart';
import 'package:studyflow/widgets/progress_card.dart';
import 'package:studyflow/widgets/scheduale_item.dart';
import 'package:studyflow/widgets/statistics_card.dart';
import 'package:studyflow/widgets/study_session_card.dart';

import '../widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsetsGeometry.all(20),
            child: Column(
              children: [
                HomeHeader(),
                SizedBox(height: 20),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    "Good Morning, Hadi",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28),
                  ),
                ),
                SizedBox(height: 5),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    "Here's your study plan for today.",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 10),
                ProgressCard(),
                SizedBox(height: 10),
                StudySessionCard(
                  subject: 'database',
                  chapter: 'lecture 1',
                  duration: '18:00 - 20:00 (120 min)',
                  status: 'planned',
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: StatisticsCard(
                        icon: Icons.check_circle_outline,
                        label: 'completed\n sessions',
                        value: '3',
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: StatisticsCard(
                        icon: Icons.timer_outlined,
                        label: 'Study\nminutes',
                        value: '180',
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: StatisticsCard(
                        icon: Icons.task_alt,
                        label: '    Tasks\ncompleted',
                        value: '5',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15,),
                Container(
                  
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  
                  child : Padding( 
                    padding: EdgeInsets.all(20),
                    child :Stack(
                      
                    children: [
                      Column(children: [
                        Align( alignment: Alignment.centerLeft,
                      child: Text("Today's Scheduale",style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),),),
                  SizedBox(height: 15,),
                  SchedualeItem(subject: 'ER Diagram Assignment', title: 'DB Systems', time:'18:00'),
                  SizedBox(height: 15,),
                  SchedualeItem(subject: 'React Hooks practice', title: 'Web Dev', time:'19:45'),
                  SizedBox(height: 15,),
                  SchedualeItem(subject: 'Dynamic programing Review', title: 'ER Diagram Assignment', time:'21:30'),
                    ],
                  )],
                  
                ),
                ),
                     
            )],
            ),
          ),
        ),
      ),
    );
  }
}
