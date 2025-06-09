import 'package:flutter/foundation.dart';
import 'package:tution/models/student.dart';
import 'package:tution/services/supabase_service.dart';

class FeeProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFeesAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await _supabaseService.getPaymentAnalytics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
