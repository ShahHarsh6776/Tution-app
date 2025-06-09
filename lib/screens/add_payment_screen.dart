import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/models/student.dart';
import 'package:tution/models/payment.dart';
import 'package:tution/providers/payment_provider.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:uuid/uuid.dart';

class AddPaymentScreen extends StatefulWidget {
  final Student student;

  const AddPaymentScreen({super.key, required this.student});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'Cash'; // Default payment mode

  final List<String> _paymentModes = ['Cash', 'UPI', 'Bank Transfer', 'Cheque'];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payment = Payment(
      id: const Uuid().v4(),
      studentId: widget.student.id,
      amount: double.parse(_amountController.text),
      paymentDate: _paymentDate,
      paymentMode: _paymentMode,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);
      final success = await paymentProvider.addPayment(payment);
      if (success) {
        // Refresh student and payment data
        await studentProvider.loadStudentById(payment.studentId);
        await paymentProvider.loadPaymentsByStudentId(payment.studentId);

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
        navigator.pop();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to add payment')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${widget.student.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentModes.map((String mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _paymentMode = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Payment Date'),
                subtitle: Text(
                  '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savePayment,
                  child: const Text('Save Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
