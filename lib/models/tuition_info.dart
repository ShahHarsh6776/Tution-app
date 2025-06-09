class TuitionInfo {
  final String? teacherName;
  final String? address;
  final String? mobileNumber;

  TuitionInfo({
    this.teacherName,
    this.address,
    this.mobileNumber,
  });

  factory TuitionInfo.fromJson(Map<String, dynamic> json) {
    return TuitionInfo(
      teacherName: json['teacher_name'],
      address: json['address'],
      mobileNumber: json['mobile_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacher_name': teacherName,
      'address': address,
      'mobile_number': mobileNumber,
    };
  }
}
