// File: lib/models/profile_model.dart

/// Defines the structure for a single Nominee.
class Nominee {
  final String name;
  final String relationship;
  final double sharePercentage;

  Nominee({
    required this.name,
    required this.relationship,
    required this.sharePercentage,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      sharePercentage: (json['sharePercentage'] as num).toDouble(),
    );
  }
}

/// Defines the structure for KYC details (Aadhaar/PAN).
class KycDetails {
  final String aadhaarNumber;
  final String panNumber;

  KycDetails({
    required this.aadhaarNumber,
    required this.panNumber,
  });

  factory KycDetails.fromJson(Map<String, dynamic> json) {
    return KycDetails(
      aadhaarNumber: json['aadhaarNumber'] as String,
      panNumber: json['panNumber'] as String,
    );
  }
}

/// The main Model class for the user's profile data.
class ProfileData {
  final String fullName;
  final String cifId;
  final String userId;
  final String emailId;
  final String mobileNumber;
  final String dateOfBirth;
  final String communicationAddress;
  final KycDetails kycDetails;
  final List<Nominee> nominees;

  ProfileData({
    required this.fullName,
    required this.cifId,
    required this.userId,
    required this.emailId,
    required this.mobileNumber,
    required this.dateOfBirth,
    required this.communicationAddress,
    required this.kycDetails,
    required this.nominees,
  });

  // Factory method to create a ProfileData object from a JSON map (e.g., from API)
  factory ProfileData.fromJson(Map<String, dynamic> json) {
    // Parse Nominees list
    final List<dynamic> nomineeListJson = json['nominees'] as List<dynamic>;
    final List<Nominee> nominees = nomineeListJson
        .map((n) => Nominee.fromJson(n as Map<String, dynamic>))
        .toList();

    return ProfileData(
      fullName: json['fullName'] as String,
      cifId: json['cifId'] as String,
      userId: json['userId'] as String,
      emailId: json['emailId'] as String,
      mobileNumber: json['mobileNumber'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      communicationAddress: json['communicationAddress'] as String,
      kycDetails: KycDetails.fromJson(json['kycDetails'] as Map<String, dynamic>),
      nominees: nominees,
    );
  }
}