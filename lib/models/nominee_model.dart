// lib/models/nominee_model.dart
class NomineeModel {
  final String id;
  final String fullName;
  final String relationship;
  final double sharePercentage;
  final String accountType;

  NomineeModel({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.sharePercentage,
    required this.accountType,
  });

  NomineeModel copyWith({
    String? id,
    String? fullName,
    String? relationship,
    double? sharePercentage,
    String? accountType,
  }) {
    return NomineeModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      sharePercentage: sharePercentage ?? this.sharePercentage,
      accountType: accountType ?? this.accountType,
    );
  }
}