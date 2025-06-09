import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tution/models/student.dart';
import 'package:tution/models/payment.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:tution/models/tuition_info.dart';

class SupabaseService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Student methods
  Future<List<Student>> getStudents() async {
    final response =
        await _supabaseClient.from('students').select().order('name');

    return (response as List).map((data) => Student.fromJson(data)).toList();
  }

  Future<Student> getStudentById(String id) async {
    final response =
        await _supabaseClient.from('students').select().eq('id', id).single();

    return Student.fromJson(response);
  }

  Future<void> addStudent(Student student) async {
    await _supabaseClient.from('students').insert(student.toJson());
  }

  Future<void> updateStudent(Student student) async {
    await _supabaseClient
        .from('students')
        .update(student.toJson())
        .eq('id', student.id);
  }

  Future<void> deleteStudent(String id) async {
    await _supabaseClient.from('students').delete().eq('id', id);
  }

  // Photo upload method
  Future<String> uploadPhoto(
      Uint8List fileBytes, String originalFileName, String studentId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${originalFileName.split('/').last}';
    final filePath = 'profile/$studentId/$fileName';

    final response = await _supabaseClient.storage
        .from('photos')
        .uploadBinary(filePath, fileBytes);

    return _supabaseClient.storage.from('photos').getPublicUrl(filePath);
  }

  // Payment methods
  Future<List<Payment>> getStudentPayments(String studentId) async {
    final response = await _supabaseClient
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('payment_date', ascending: false);

    return (response as List).map((data) => Payment.fromJson(data)).toList();
  }

  Future<void> addPayment(Payment payment) async {
    await _supabaseClient.from('payments').insert(payment.toJson());
  }

  Future<void> deletePayment(String paymentId) async {
    await _supabaseClient.from('payments').delete().eq('id', paymentId);
  }

  Future<Map<String, dynamic>> getPaymentAnalytics() async {
    final students = await getStudents();
    double totalFees = 0;
    double totalCollected = 0;

    for (var student in students) {
      totalFees += student.totalFees;
      totalCollected += student.feesSubmitted;
    }

    final totalPending = totalFees - totalCollected;
    final collectionPercentage =
        totalFees > 0 ? (totalCollected / totalFees) * 100 : 0;

    return {
      'totalFees': totalFees,
      'totalCollected': totalCollected,
      'totalPending': totalPending,
      'collectionPercentage': collectionPercentage,
    };
  }

  Future<void> clearAllPaymentsForStudent(String studentId) async {
    await _supabaseClient.from('payments').delete().eq('student_id', studentId);
    await _supabaseClient
        .from('students')
        .update({'fees_submitted': 0}).eq('id', studentId);
  }

  // Tuition Info methods
  Future<void> saveTuitionInfo(TuitionInfo info) async {
    // Assuming a single row with a fixed ID, e.g., 'tuition_data'
    await _supabaseClient.from('tuition_info').upsert(
          info.toJson()..['id'] = 'tuition_data',
          onConflict: 'id',
        );
  }

  Future<TuitionInfo?> getTuitionInfo() async {
    try {
      final response = await _supabaseClient
          .from('tuition_info')
          .select()
          .eq('id', 'tuition_data')
          .single();
      return TuitionInfo.fromJson(response);
    } catch (e) {
      // Handle the case where the row doesn't exist yet
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null;
      }
      rethrow; // Rethrow other errors
    }
  }
}
