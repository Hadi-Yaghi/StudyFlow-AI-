import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "StudyFlow",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 25,
                color:  Color.fromRGBO(53, 37, 205, 1.2),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              alignment: Alignment.center,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_sharp),
              ),
            ),
            SizedBox(width: 10),

            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/study_flow_logo.png'),
            ),
          ],
        ),
      ],
    );
  }
}
