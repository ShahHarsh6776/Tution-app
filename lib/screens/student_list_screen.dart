import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/models/student.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:tution/screens/student_details_screen.dart';
import 'package:tution/screens/add_edit_student_screen.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadStudents(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No students found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditStudentScreen(),
                        ),
                      );
                    },
                    child: const Text('Add Student'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadStudents(),
            child: ListView.builder(
              itemCount: provider.students.length,
              itemBuilder: (context, index) {
                final student = provider.students[index];
                return StudentListItem(student: student);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditStudentScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StudentListItem extends StatelessWidget {
  final Student student;

  const StudentListItem({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
          child: student.photoUrl == null
              ? Text(student.name[0].toUpperCase())
              : null,
        ),
        title: Text(student.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${student.schoolName} - ${student.standard}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: student.feesSubmitted / student.totalFees,
              backgroundColor: Colors.grey[300],
              color: _getProgressColor(student.feesPercentage),
            ),
            const SizedBox(height: 4),
            Text(
              'Fees: ₹${student.feesSubmitted.toStringAsFixed(2)} / ₹${student.totalFees.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsScreen(studentId: student.id),
            ),
          );
        },
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
