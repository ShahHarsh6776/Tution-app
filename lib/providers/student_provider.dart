import 'package:flutter/material.dart';
import 'package:tution/models/student.dart';
import 'package:tution/models/payment.dart';
import 'package:tution/services/supabase_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:tution/providers/payment_provider.dart';
import 'package:uuid/uuid.dart'; // New import for UUID generation

class StudentProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final Uuid _uuid = Uuid(); // Instance of Uuid for generating student IDs
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _supabaseService.getStudents();
    } catch (e) {
      _error = 'Failed to load students: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final student = await _supabaseService.getStudentById(id);
      final index = _students.indexWhere((s) => s.id == id);
      if (index != -1) {
        _students[index] = student;
      } else {
        _students.add(student);
      }
    } catch (e) {
      _error = 'Failed to load student: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Student? getStudentById(String id) {
    return _students.firstWhere(
      (student) => student.id == id,
      orElse: () => throw Exception('Student not found'),
    );
  }

  Future<Student?> addStudent(Student student, {dynamic photoFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Assign a UUID to student if not already assigned
      if (student.id == null || student.id!.isEmpty) {
        student = student.copyWith(id: _uuid.v4());
      }

      if (photoFile != null) {
        String originalFileName;
        Uint8List fileBytes;

        if (photoFile is File) {
          originalFileName = photoFile.path.split('/').last;
          fileBytes = await photoFile.readAsBytes();
        } else if (photoFile is XFile) {
          originalFileName = photoFile.name;
          fileBytes = await photoFile.readAsBytes();
        } else {
          throw Exception('Unsupported photo file type');
        }

        final photoUrl = await _supabaseService.uploadPhoto(
            fileBytes, originalFileName, student.id!);
        student = student.copyWith(photoUrl: photoUrl);
      }

      await _supabaseService.addStudent(student);
      _students.add(student);
      _students.sort((a, b) => a.name.compareTo(b.name));
      return student;
    } catch (e) {
      _error = 'Failed to add student: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Student?> updateStudent(Student student, {dynamic photoFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (photoFile != null) {
        String originalFileName;
        Uint8List fileBytes;

        if (photoFile is File) {
          originalFileName = photoFile.path.split('/').last;
          fileBytes = await photoFile.readAsBytes();
        } else if (photoFile is XFile) {
          originalFileName = photoFile.name;
          fileBytes = await photoFile.readAsBytes();
        } else {
          throw Exception('Unsupported photo file type');
        }

        final photoUrl = await _supabaseService.uploadPhoto(
            fileBytes, originalFileName, student.id!);
        student = student.copyWith(photoUrl: photoUrl);
      }

      await _supabaseService.updateStudent(student);
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student;
      }
      return student;
    } catch (e) {
      _error = 'Failed to update student: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStudent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.deleteStudent(id);
      _students.removeWhere((student) => student.id == id);
      return true;
    } catch (e) {
      _error = 'Failed to delete student: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Payment>> getStudentPayments(String studentId) async {
    try {
      return await _supabaseService.getStudentPayments(studentId);
    } catch (e) {
      _error = 'Failed to load payments: $e';
      return [];
    }
  }

  Future<bool> addPayment(Payment payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.addPayment(payment);

      final student = await _supabaseService.getStudentById(payment.studentId);
      final index = _students.indexWhere((s) => s.id == payment.studentId);
      if (index != -1) {
        _students[index] = student;
      }

      return true;
    } catch (e) {
      _error = 'Failed to add payment: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getFeesAnalytics() async {
    try {
      return await _supabaseService.getPaymentAnalytics();
    } catch (e) {
      _error = 'Failed to load analytics: $e';
      return {
        'totalFees': 0.0,
        'totalCollected': 0.0,
        'totalPending': 0.0,
        'collectionPercentage': 0.0,
      };
    }
  }

  Future<void> clearAllPayments(
      String studentId, PaymentProvider paymentProvider) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.clearAllPaymentsForStudent(studentId);
      await loadStudentById(studentId);
      await paymentProvider.loadPaymentsByStudentId(studentId);
    } catch (e) {
      _error = 'Failed to clear payments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
