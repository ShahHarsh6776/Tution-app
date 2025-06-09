import 'package:flutter/material.dart';

class StudentCard extends StatelessWidget {
  final String name;
  final String studentClass;
  final double paid;
  final double total;
  final double percent;
  final String pending;

  const StudentCard({
    required this.name,
    required this.studentClass,
    required this.paid,
    required this.total,
    required this.percent,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              child: Text(name[0].toUpperCase(),
                  style: TextStyle(fontSize: 24, color: Colors.blue)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Class: $studentClass',
                      style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                          '₹${paid.toStringAsFixed(2)} / ₹${total.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Spacer(),
                      Text('Pending: ₹$pending',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
