import 'package:flutter/material.dart';

class StudySessionCard extends StatelessWidget {
  final String subject;
  final String chapter;
  final String duration;
  final String status;
  const StudySessionCard({
    required this.subject,
    required this.chapter,
    required this.duration,
    required this.status,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E1FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subject.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color:Color.fromRGBO(7 ,0 ,108,1),
                    ),
                  ),
                ),
                SizedBox(width: 5),

                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(237 ,238 ,239,1 ),
                    borderRadius: BorderRadius.circular(8),
                   
                  ),

                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        
                      ),
                    ),
                  ),
                  
                ),
              ],
            ),
            SizedBox(height: 10,),
            Align(
              alignment: AlignmentGeometry.centerLeft,
              child :Text(chapter.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
            )),
            SizedBox(height: 10,),
            Row(children: [
              Icon(Icons.schedule,size: 20,),
              SizedBox(width: 5,),
              Text(duration)
            ],),
            SizedBox(height: 25,),
            ElevatedButton(onPressed: (){

            }, style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(53, 37, 205, 1.0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Align(
                    alignment: AlignmentGeometry.center,

                    child :Text("Start Session",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),) )
          ],
        ),
      ),
    );
  }
}
