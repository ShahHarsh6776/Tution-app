class FeePayment {
  final String id;
  final String studentId;
  final double amount;
  final String paymentMode;
  final DateTime paymentDate;
  final String? notes;

  FeePayment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    this.notes,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: json['id'],
      studentId: json['student_id'],
      amount: json['amount'].toDouble(),
      paymentMode: json['payment_mode'],
      paymentDate: DateTime.parse(json['payment_date']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'payment_mode': paymentMode,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
    };
  }
}