import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                    value: 0.6,
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
                    const Text("3/5 sessions completed"),
                    const Text("180/300 min",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color.fromRGBO(53, 37, 205, 1),
                    ),),
                  ],
                ),

                const SizedBox(height: 8),

                const LinearProgressIndicator(
                  value: 0.6,
                  
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}