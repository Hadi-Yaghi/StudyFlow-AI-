import 'package:flutter/material.dart';
class HomeHeader extends StatelessWidget {
  final String username;
  const HomeHeader({
    
    super.key,
    required this.username});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment : MainAxisAlignment.spaceBetween,
      children: [
        
        Row(children: [
          Align(
            alignment: Alignment.centerLeft,
            child : Text("StudyFlow",
            style: 
            TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 18,
              color: Colors.blueAccent,
            ),)
          ),
          
        ],),
        Row(children: [
          Container(
            alignment: Alignment.center, 
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius  :  BorderRadius.circular(20),
              color: Colors.white,
            ),
            child : IconButton(onPressed: (){

            }, icon: Icon(Icons.notifications_sharp)),
          ),
           SizedBox(width: 10,),
           
            
            CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/study_flow_logo.png',
                
                ),
                
            
            )
            
           
          
          
        ],),
      ],
    );
  }
}