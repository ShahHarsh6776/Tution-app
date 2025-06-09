import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/models/student.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:tution/screens/add_edit_student_screen.dart';
import 'package:tution/screens/student_details_screen.dart';
import 'package:tution/screens/analytics_screen.dart';
import 'package:tution/screens/profile_screen.dart';
import 'package:tution/widgets/student_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String? _selectedSchool;
  String? _selectedStandard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuition Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            tooltip: 'Profile',
          ),
        ],
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
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadStudents();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.students.isEmpty) {
            return const Center(
              child: Text('No students found. Add a student to get started.'),
            );
          }

          // Get unique school names and standards for filters
          final schools = provider.students
              .map((s) => s.schoolName)
              .toSet()
              .toList()
            ..sort();
          final standards =
              provider.students.map((s) => s.standard).toSet().toList()..sort();

          // Filter students
          final filteredStudents = provider.students.where((student) {
            final matchesName =
                student.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesSchool = _selectedSchool == null ||
                student.schoolName == _selectedSchool;
            final matchesStandard = _selectedStandard == null ||
                student.standard == _selectedStandard;
            return matchesName && matchesSchool && matchesStandard;
          }).toList();

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(_selectedSchool ?? 'All Schools'),
                      selected: _selectedSchool != null,
                      onSelected: (selected) async {
                        if (selected) {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select School'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: schools.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return ListTile(
                                        title: const Text('All Schools'),
                                        onTap: () =>
                                            Navigator.pop(context, null),
                                      );
                                    }
                                    return ListTile(
                                      title: Text(schools[index - 1]),
                                      onTap: () => Navigator.pop(
                                          context, schools[index - 1]),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _selectedSchool = result;
                            });
                          }
                        } else {
                          setState(() {
                            _selectedSchool = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(_selectedStandard ?? 'All Classes'),
                      selected: _selectedStandard != null,
                      onSelected: (selected) async {
                        if (selected) {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select Class'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: standards.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return ListTile(
                                        title: const Text('All Classes'),
                                        onTap: () =>
                                            Navigator.pop(context, null),
                                      );
                                    }
                                    return ListTile(
                                      title: Text(standards[index - 1]),
                                      onTap: () => Navigator.pop(
                                          context, standards[index - 1]),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _selectedStandard = result;
                            });
                          }
                        } else {
                          setState(() {
                            _selectedStandard = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(
                        child: Text('No students match your search/filter.'))
                    : ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailsScreen(
                                      studentId: student.id),
                                ),
                              );
                              setState(() {
                                _searchQuery = '';
                                _selectedSchool = null;
                                _selectedStandard = null;
                              });
                            },
                            child: StudentCard(
                              name: student.name,
                              studentClass: student.standard,
                              paid: student.feesSubmitted,
                              total: student.totalFees,
                              percent: student.totalFees == 0
                                  ? 0
                                  : student.feesSubmitted / student.totalFees,
                              pending:
                                  (student.totalFees - student.feesSubmitted)
                                      .toStringAsFixed(2),
                            ),
                          );
                        },
                      ),
              ),
            ],
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
