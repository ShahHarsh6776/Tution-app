import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/models/student.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:tution/providers/tuition_info_provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentFeeSummaryScreen extends StatefulWidget {
  const StudentFeeSummaryScreen({super.key});

  @override
  State<StudentFeeSummaryScreen> createState() =>
      _StudentFeeSummaryScreenState();
}

class _StudentFeeSummaryScreenState extends State<StudentFeeSummaryScreen> {
  final DateFormat _fullDateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  String? selectedSchool;
  String? selectedClass;
  List<String> availableSchools = [];
  List<String> availableClasses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadStudents();
      Provider.of<TuitionInfoProvider>(context, listen: false)
          .loadTuitionInfo();
      _loadFilterOptions();
    });
  }

  void _loadFilterOptions() {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final students = studentProvider.students;

    // Extract unique schools and classes
    final schools = students.map((s) => s.schoolName).toSet().toList();
    final classes = students.map((s) => s.standard).toSet().toList();

    setState(() {
      availableSchools = schools;
      availableClasses = classes;
    });
  }

  List<Student> _getFilteredStudents(List<Student> allStudents) {
    return allStudents.where((student) {
      bool matchesSchool =
          selectedSchool == null || student.schoolName == selectedSchool;
      bool matchesClass =
          selectedClass == null || student.standard == selectedClass;
      return matchesSchool && matchesClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Fee Summary Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _generatePDF(context),
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredStudents =
              _getFilteredStudents(studentProvider.students);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSection(),
                const SizedBox(height: 24),
                _buildSummarySection(filteredStudents),
                const SizedBox(height: 24),
                _buildStudentsTable(filteredStudents),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'School',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSchool,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Schools')),
                      ...availableSchools.map((school) =>
                          DropdownMenuItem(value: school, child: Text(school))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSchool = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClass,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Classes')),
                      ...availableClasses.map((cls) =>
                          DropdownMenuItem(value: cls, child: Text(cls))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<Student> students) {
    final totalStudents = students.length;
    final totalFees =
        students.fold<double>(0, (sum, student) => sum + student.totalFees);
    final totalPaid =
        students.fold<double>(0, (sum, student) => sum + student.feesSubmitted);
    final totalRemaining = totalFees - totalPaid;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Students: $totalStudents',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Fees: ${totalFees.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Paid: ${totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Remaining: ${totalRemaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: totalRemaining > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTable(List<Student> students) {
    if (students.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No students found matching the selected filters',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Table Header
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: _TableHeaderCell('Student Name')),
                  Expanded(flex: 1, child: _TableHeaderCell('Class')),
                  Expanded(flex: 2, child: _TableHeaderCell('Parent Mobile')),
                  Expanded(flex: 1, child: _TableHeaderCell('Total Fees')),
                  Expanded(flex: 1, child: _TableHeaderCell('Total Paid')),
                  Expanded(flex: 1, child: _TableHeaderCell('Total Left')),
                ],
              ),
            ),
            // Table Rows
            ...students
                .map((student) => Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                          right: BorderSide(color: Colors.grey[300]!),
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2, child: _TableDataCell(student.name)),
                          Expanded(
                              flex: 1, child: _TableDataCell(student.standard)),
                          Expanded(
                              flex: 2,
                              child: _TableDataCell(student.parentNumber)),
                          Expanded(
                              flex: 1,
                              child: _TableDataCell(
                                  student.totalFees.toStringAsFixed(2))),
                          Expanded(
                              flex: 1,
                              child: _TableDataCell(
                                  student.feesSubmitted.toStringAsFixed(2))),
                          Expanded(
                            flex: 1,
                            child: _TableDataCell(
                              student.remainingFees.toStringAsFixed(2),
                              color: student.remainingFees > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final tuitionInfoProvider =
        Provider.of<TuitionInfoProvider>(context, listen: false);
    final tuitionInfo = tuitionInfoProvider.tuitionInfo;

    final filteredStudents = _getFilteredStudents(studentProvider.students);

    if (filteredStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to generate report for')),
      );
      return;
    }

    final pdf = pw.Document();

    // Calculate totals
    final totalStudents = filteredStudents.length;
    final totalFees = filteredStudents.fold<double>(
        0, (sum, student) => sum + student.totalFees);
    final totalPaid = filteredStudents.fold<double>(
        0, (sum, student) => sum + student.feesSubmitted);
    final totalRemaining = totalFees - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              children: [
                pw.Text(
                  'Student Fee Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated on: ${_fullDateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              children: [
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                if (tuitionInfo?.teacherName != null)
                  pw.Text(
                    'Teacher: ${tuitionInfo!.teacherName}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                if (tuitionInfo?.address != null)
                  pw.Text(
                    'Address: ${tuitionInfo!.address}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                if (tuitionInfo?.mobileNumber != null)
                  pw.Text(
                    'Contact: ${tuitionInfo!.mobileNumber}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Filter Information
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Filter Information',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (selectedSchool != null)
                    pw.Text('School: $selectedSchool',
                        style: pw.TextStyle(fontSize: 12)),
                  if (selectedClass != null)
                    pw.Text('Class: $selectedClass',
                        style: pw.TextStyle(fontSize: 12)),
                  if (selectedSchool == null && selectedClass == null)
                    pw.Text('All Schools and Classes',
                        style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Students: $totalStudents',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Fees: ${totalFees.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Paid: ${totalPaid.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Remaining: ${totalRemaining.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: totalRemaining > 0
                              ? PdfColors.red
                              : PdfColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Students Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5), // Student Name
                1: const pw.FlexColumnWidth(1), // Class
                2: const pw.FlexColumnWidth(2), // Parent Mobile
                3: const pw.FlexColumnWidth(1.2), // Total Fees
                4: const pw.FlexColumnWidth(1.2), // Total Paid
                5: const pw.FlexColumnWidth(1.2), // Total Left
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildPdfHeaderCell('Student Name'),
                    _buildPdfHeaderCell('Class'),
                    _buildPdfHeaderCell('Parent Mobile'),
                    _buildPdfHeaderCell('Total Fees'),
                    _buildPdfHeaderCell('Total Paid'),
                    _buildPdfHeaderCell('Total Left'),
                  ],
                ),
                // Data rows
                ...filteredStudents.map((student) => pw.TableRow(
                      children: [
                        _buildPdfDataCell(student.name),
                        _buildPdfDataCell(student.standard),
                        _buildPdfDataCell(student.parentNumber),
                        _buildPdfDataCell(student.totalFees.toStringAsFixed(2)),
                        _buildPdfDataCell(
                            student.feesSubmitted.toStringAsFixed(2)),
                        _buildPdfDataCell(
                          student.remainingFees.toStringAsFixed(2),
                          color: student.remainingFees > 0
                              ? PdfColors.red
                              : PdfColors.green,
                        ),
                      ],
                    )),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfDataCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableDataCell extends StatelessWidget {
  final String text;
  final Color? color;

  const _TableDataCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
