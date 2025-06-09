class Payment {
  final String id;
  final String studentId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMode;
  final String? notes;

  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      studentId: json['student_id'],
      amount: json['amount'].toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      paymentMode: json['payment_mode'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_mode': paymentMode,
      'notes': notes,
    };
  }
}
