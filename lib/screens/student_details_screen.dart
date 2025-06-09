import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/models/student.dart';
import 'package:tution/models/payment.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:tution/providers/payment_provider.dart';
import 'package:tution/screens/add_edit_student_screen.dart';
import 'package:tution/screens/add_payment_screen.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false)
          .loadStudentById(widget.studentId);
      Provider.of<PaymentProvider>(context, listen: false)
          .loadPaymentsByStudentId(widget.studentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Payment PDF',
            onPressed: () => _downloadStudentPaymentsPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final student =
                  Provider.of<StudentProvider>(context, listen: false)
                      .getStudentById(widget.studentId);
              if (student != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditStudentScreen(student: student),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Student',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Student?'),
                  content: const Text(
                      'Are you sure you want to delete this student? This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true) {
                final success =
                    await Provider.of<StudentProvider>(context, listen: false)
                        .deleteStudent(widget.studentId);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Student deleted successfully.')));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Failed to delete student.')));
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          final student = studentProvider.getStudentById(widget.studentId);

          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (student == null) {
            return const Center(child: Text('Student not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(student),
              _buildPaymentsTab(student),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          final student = studentProvider.getStudentById(widget.studentId);
          if (student == null) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentScreen(student: student),
                ),
              );
            },
            child: const Icon(Icons.payment),
          );
        },
      ),
    );
  }

  Widget _buildProfileTab(Student student) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Hero(
              tag: 'student_photo_${student.id}',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: student.photoUrl != null
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: student.photoUrl == null
                    ? Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              student.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Class: ${student.standard}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          _buildInfoRow('Medium', student.medium ?? '-'),
          _buildInfoRow('School', student.schoolName),
          _buildInfoRow(
              'Total Fees', '₹${student.totalFees.toStringAsFixed(2)}'),
          _buildInfoRow(
              'Fees Paid', '₹${student.feesSubmitted.toStringAsFixed(2)}'),
          _buildInfoRow(
            'Remaining Fees',
            '₹${student.remainingFees.toStringAsFixed(2)}',
            valueColor: student.remainingFees > 0 ? Colors.red : Colors.green,
          ),
          _buildInfoRow(
            'Payment Status',
            '${student.feesPercentage.toStringAsFixed(0)}% Complete',
          ),
          _buildProgressBar(student.feesPercentage / 100),
          const Divider(),
          _buildInfoRow('Parent Contact', student.parentNumber),
          if (student.additionalParentNumber != null &&
              student.additionalParentNumber!.isNotEmpty)
            _buildInfoRow(
                'Additional Parent Contact', student.additionalParentNumber),
          _buildInfoRow('Address', student.address),
          if (student.description != null && student.description!.isNotEmpty)
            _buildInfoRow('Notes', student.description!),
          const Divider(),
          _buildInfoRow('Admission Date', dateFormat.format(student.createdAt)),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(Student student) {
    return Consumer2<PaymentProvider, StudentProvider>(
      builder: (context, paymentProvider, studentProvider, child) {
        if (paymentProvider.isLoading || studentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments =
            paymentProvider.getPaymentsByStudentId(widget.studentId);
        return Column(
          children: [
            if (payments.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All Payments'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Payments?'),
                        content: const Text(
                            'Are you sure you want to delete all payment history for this student? This cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await studentProvider.clearAllPayments(
                          student.id, paymentProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('All payments cleared.')));
                    }
                  },
                ),
              ),
            Expanded(
              child: payments.isEmpty
                  ? const Center(child: Text('No payment records found'))
                  : ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return _buildPaymentItem(payment);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          value < 1.0 ? Colors.orange : Colors.green,
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  payment.paymentMode,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(payment.paymentDate),
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text(
                payment.notes!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadStudentPaymentsPdf(BuildContext context) async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final student = studentProvider.getStudentById(widget.studentId);
    if (student == null) return;
    final payments = await studentProvider.getStudentPayments(student.id);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
              level: 0,
              child: pw.Text('Payment Transactions for ${student.name}',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Text('Class: ${student.standard}'),
          pw.Text('School: ${student.schoolName}'),
          pw.Text('Medium: ${student.medium ?? '-'}'),
          pw.Text('Parent Contact: ${student.parentNumber}'),
          pw.Text('Address: ${student.address}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Payment Date',
              'Amount',
              'Mode',
              'Notes',
            ],
            data: payments
                .map((payment) => [
                      payment.paymentDate.toString().substring(0, 16),
                      payment.amount.toStringAsFixed(2),
                      payment.paymentMode,
                      payment.notes ?? '-',
                    ])
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Payment Date
              1: const pw.FlexColumnWidth(1), // Amount
              2: const pw.FlexColumnWidth(1), // Mode
              3: const pw.FlexColumnWidth(2), // Notes
            },
          ),
          pw.SizedBox(height: 16),
          pw.Row(children: [
            pw.Text('Total Fees: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(student.totalFees.toStringAsFixed(2)),
            pw.Spacer(),
            pw.Text('Fees Received: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(student.feesSubmitted.toStringAsFixed(2)),
            pw.Spacer(),
            pw.Text('Remaining Fees: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(student.remainingFees.toStringAsFixed(2)),
          ]),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
