import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/providers/tuition_info_provider.dart';
import 'package:tution/models/tuition_info.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:tution/models/student.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _teacherNameController = TextEditingController();
  final _tuitionAddressController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    // Load existing tuition information
    Provider.of<TuitionInfoProvider>(context, listen: false)
        .loadTuitionInfo()
        .then((_) {
      final tuitionInfo =
          Provider.of<TuitionInfoProvider>(context, listen: false).tuitionInfo;
      if (tuitionInfo != null) {
        _teacherNameController.text = tuitionInfo.teacherName ?? '';
        _tuitionAddressController.text = tuitionInfo.address ?? '';
        _mobileNumberController.text = tuitionInfo.mobileNumber ?? '';
      }
    });
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    _tuitionAddressController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _generateParentWiseReport() async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final tuitionInfoProvider =
        Provider.of<TuitionInfoProvider>(context, listen: false);
    final tuitionInfo = tuitionInfoProvider.tuitionInfo;

    // Group students by parent mobile number
    final Map<String, List<Student>> parentGroups = {};
    for (var student in studentProvider.students) {
      final parentNumber = student.parentNumber;
      if (!parentGroups.containsKey(parentNumber)) {
        parentGroups[parentNumber] = [];
      }
      parentGroups[parentNumber]!.add(student);
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Parent-wise Student Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            'Generated on: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Student Name
              1: const pw.FlexColumnWidth(1), // Class
              2: const pw.FlexColumnWidth(2), // Parent Mobile
              3: const pw.FlexColumnWidth(1.5), // Total Fees
              4: const pw.FlexColumnWidth(1.5), // Total Paid
              5: const pw.FlexColumnWidth(1.5), // Total Left
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  _buildHeaderCell('Student Name'),
                  _buildHeaderCell('Class'),
                  _buildHeaderCell('Parent Mobile'),
                  _buildHeaderCell('Total Fees'),
                  _buildHeaderCell('Total Paid'),
                  _buildHeaderCell('Total Left'),
                ],
              ),
              // Data rows
              ...parentGroups.entries.expand((entry) {
                final students = entry.value;
                return students.map((student) {
                  return pw.TableRow(
                    children: [
                      _buildDataCell(student.name),
                      _buildDataCell(student.standard),
                      _buildDataCell(student.parentNumber),
                      _buildDataCell(student.totalFees.toStringAsFixed(2)),
                      _buildDataCell(student.feesSubmitted.toStringAsFixed(2)),
                      _buildDataCell(
                        student.remainingFees.toStringAsFixed(2),
                        color: student.remainingFees > 0
                            ? PdfColors.red
                            : PdfColors.green,
                      ),
                    ],
                  );
                });
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  tuitionInfo?.teacherName ?? 'Tuition Center',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  tuitionInfo?.address ?? '',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Phone: ${tuitionInfo?.mobileNumber ?? ''}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'This is a computer-generated report. No signature is required.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildDataCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile and Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _teacherNameController,
              decoration: const InputDecoration(
                labelText: 'Teacher Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tuitionAddressController,
              decoration: const InputDecoration(
                labelText: 'Tuition Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileNumberController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final provider =
                    Provider.of<TuitionInfoProvider>(context, listen: false);
                final tuitionInfo = TuitionInfo(
                  teacherName: _teacherNameController.text.isEmpty
                      ? null
                      : _teacherNameController.text,
                  address: _tuitionAddressController.text.isEmpty
                      ? null
                      : _tuitionAddressController.text,
                  mobileNumber: _mobileNumberController.text.isEmpty
                      ? null
                      : _mobileNumberController.text,
                );
                await provider.saveTuitionInfo(tuitionInfo);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(provider.error ??
                          'Tuition information saved successfully!')),
                );
              },
              child: const Text('Save Information'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateParentWiseReport,
              icon: const Icon(Icons.summarize),
              label: const Text('Generate Parent-wise Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
