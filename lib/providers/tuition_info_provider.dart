import 'package:flutter/foundation.dart';
import 'package:tution/services/supabase_service.dart';
import 'package:tution/models/tuition_info.dart';

class TuitionInfoProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  TuitionInfo? _tuitionInfo;
  bool _isLoading = false;
  String? _error;

  TuitionInfo? get tuitionInfo => _tuitionInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTuitionInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tuitionInfo = await _supabaseService.getTuitionInfo();
    } catch (e) {
      _error = 'Failed to load tuition information: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveTuitionInfo(TuitionInfo info) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.saveTuitionInfo(info);
      _tuitionInfo = info;
    } catch (e) {
      _error = 'Failed to save tuition information: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
