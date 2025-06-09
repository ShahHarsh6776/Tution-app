import 'package:flutter/foundation.dart';
import 'package:tution/models/payment.dart';
import 'package:tution/services/supabase_service.dart';

class PaymentProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Payment> getPaymentsByStudentId(String studentId) {
    return _payments.where((payment) => payment.studentId == studentId).toList();
  }

  Future<void> loadPaymentsByStudentId(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _payments = await _supabaseService.getStudentPayments(studentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPayment(Payment payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.addPayment(payment);
      _payments.add(payment);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.deletePayment(paymentId);
      _payments.removeWhere((payment) => payment.id == paymentId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}