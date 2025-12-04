// File: lib/models/nominee_model.dart

/// Represents a single nominee associated with an account.
class NomineeModel {
  final String id;
  final String fullName;
  final String relationship;
  final double sharePercentage;
  final String accountType; // e.g., 'Savings', 'Fixed Deposit'

  NomineeModel({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.sharePercentage,
    required this.accountType,
  });

  /// Factory constructor to create a NomineeModel from a JSON map (e.g., from an API response).
  factory NomineeModel.fromJson(Map<String, dynamic> json) {
    return NomineeModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      relationship: json['relationship'] as String,
      sharePercentage: (json['sharePercentage'] as num).toDouble(),
      accountType: json['accountType'] as String,
    );
  }

  /// Converts the NomineeModel instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'relationship': relationship,
      'sharePercentage': sharePercentage,
      'accountType': accountType,
    };
  }

  /// Creates a copy of the model, optionally with updated values.
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