class Student {
  final String id;
  final String name;
  final String? photoUrl;
  final String schoolName;
  final String standard;
  final double totalFees;
  final String parentNumber;
  final String? address;
  final double feesSubmitted;
  final String? description;
  final String? medium;
  final DateTime createdAt;
  final String? additionalParentNumber;

  Student({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.schoolName,
    required this.standard,
    required this.totalFees,
    required this.parentNumber,
    required this.address,
    required this.feesSubmitted,
    this.description,
    this.medium,
    required this.createdAt,
    this.additionalParentNumber,
  });

  double get remainingFees => totalFees - feesSubmitted;
  double get feesPercentage => (feesSubmitted / totalFees) * 100;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      photoUrl: json['photo_url'],
      schoolName: json['school_name'],
      standard: json['standard'],
      totalFees: json['total_fees'].toDouble(),
      parentNumber: json['parent_number'],
      address: json['address'],
      feesSubmitted: json['fees_submitted'].toDouble(),
      description: json['description'],
      medium: json['medium'],
      createdAt: DateTime.parse(json['created_at']),
      additionalParentNumber: json['additional_parent_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo_url': photoUrl,
      'school_name': schoolName,
      'standard': standard,
      'total_fees': totalFees,
      'parent_number': parentNumber,
      'address': address,
      'fees_submitted': feesSubmitted,
      'description': description,
      'medium': medium,
      'created_at': createdAt.toIso8601String(),
      'additional_parent_number': additionalParentNumber,
    };
  }

  Student copyWith({
    String? name,
    String? photoUrl,
    String? schoolName,
    String? standard,
    double? totalFees,
    String? parentNumber,
    String? address,
    double? feesSubmitted,
    String? description,
    String? medium,
    String? additionalParentNumber,
    String? id,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      schoolName: schoolName ?? this.schoolName,
      standard: standard ?? this.standard,
      totalFees: totalFees ?? this.totalFees,
      parentNumber: parentNumber ?? this.parentNumber,
      address: address ?? this.address,
      feesSubmitted: feesSubmitted ?? this.feesSubmitted,
      description: description ?? this.description,
      medium: medium ?? this.medium,
      createdAt: this.createdAt,
      additionalParentNumber:
          additionalParentNumber ?? this.additionalParentNumber,
    );
  }
}
