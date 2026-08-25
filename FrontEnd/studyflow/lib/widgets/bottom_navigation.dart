import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final void Function(int) onItemSelected;
  final int selectedIndex;

  const BottomNavigation({
    required this.onItemSelected,
    required this.selectedIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: Colors.white,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home
              InkWell(
                onTap: () {
                  onItemSelected(0);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: selectedIndex == 0
                          ? const Color(0xFF3525CD)
                          : const Color(0xFF464555),
                    ),
                    Text(
                      "Home",
                      style: TextStyle(
                        color: selectedIndex == 0
                            ? const Color(0xFF3525CD)
                            : const Color(0xFF464555),
                      ),
                    ),
                  ],
                ),
              ),
              // Schedule
              InkWell(
                onTap: (){ 
                  onItemSelected(1);
                },
              
              child :Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_outlined,
                   color: selectedIndex == 1
                          ? const Color(0xFF3525CD)
                          : const Color(0xFF464555),),
                  Text("Schedule",
                    style: TextStyle(
                        color: selectedIndex == 1
                            ? const Color(0xFF3525CD)
                            : const Color(0xFF464555),
                      ),),
                ],
              ),
              ),
              // Tasks
              InkWell(
                 onTap: () {
                  onItemSelected(2);
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_outlined,
                  color: selectedIndex == 2
                          ? const Color(0xFF3525CD)
                          : const Color(0xFF464555),
                  ),
                  Text("Tasks",
                  style: TextStyle(
                        color: selectedIndex == 2
                            ? const Color(0xFF3525CD)
                            : const Color(0xFF464555),
                      ),),
                ],
              ),
              ),
              InkWell(  
                 onTap: () {
                  onItemSelected(3);
                }, // Courses
              child :  Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined,
                  color: selectedIndex == 3
                          ? const Color(0xFF3525CD)
                          : const Color(0xFF464555),
                  ),
                  Text("Courses",
                  style: TextStyle(
                        color: selectedIndex == 3
                            ? const Color(0xFF3525CD)
                            : const Color(0xFF464555),
                      ),),
                ],
              ),
                ),
              // Profile
              InkWell(
                onTap: (){
                  onItemSelected(4);
                },
              child  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outlined,
                  color: selectedIndex == 4
                            ? const Color(0xFF3525CD)
                            : const Color(0xFF464555),
                      ),
                  Text("Profile",
                  style: TextStyle(
                        color: selectedIndex == 4
                            ? const Color(0xFF3525CD)
                            : const Color(0xFF464555),
                      ),
                  ),
                ],
              ),
              )
            ],
          ),
        ),
      ),
    );
  }
}