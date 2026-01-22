//
class KycDetails {
  final String aadhaarNumber;
  final String panNumber;

  KycDetails({required this.aadhaarNumber, required this.panNumber});

  factory KycDetails.fromJson(Map<String, dynamic> json) {
    return KycDetails(
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
    );
  }
}

class ProfileData {
  final String fullName;
  final String cifId;
  final String mobileNumber;
  final String dateOfBirth;
  final String emailId;
  final String communicationAddress;
  final KycDetails kycDetails;
  final DateTime lastLoginTimestamp;

  ProfileData({
    required this.fullName,
    required this.cifId,
    required this.mobileNumber,
    required this.dateOfBirth,
    required this.emailId,
    required this.communicationAddress,
    required this.kycDetails,
    required this.lastLoginTimestamp,
  });

  // Used for updating local state before/after API calls
  ProfileData copyWith({
    String? emailId,
    String? communicationAddress,
  }) {
    return ProfileData(
      fullName: fullName,
      cifId: cifId,
      mobileNumber: mobileNumber,
      dateOfBirth: dateOfBirth,
      emailId: emailId ?? this.emailId,
      communicationAddress: communicationAddress ?? this.communicationAddress,
      kycDetails: kycDetails,
      lastLoginTimestamp: lastLoginTimestamp,
    );
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      fullName: json['fullName'] ?? '',
      cifId: json['cifId'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      emailId: json['emailId'] ?? '',
      communicationAddress: json['communicationAddress'] ?? '',
      kycDetails: KycDetails.fromJson(json['kycDetails'] ?? {}),
      lastLoginTimestamp: json['lastLoginTimestamp'] != null
          ? DateTime.parse(json['lastLoginTimestamp'])
          : DateTime.now(),
    );
  }
}