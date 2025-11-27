// File: lib/services/profile_service.dart

import 'package:flutter/material.dart'; // Used for Future/Duration, but minimal
import 'dart:async'; // For Future

// --- MODEL DEFINITIONS (Separated from UI) ---

class KycDetails {
  final String aadhaarNumber;
  final String panNumber;
  KycDetails({required this.aadhaarNumber, required this.panNumber});

  factory KycDetails.fromJson(Map<String, dynamic> json) {
    return KycDetails(
      aadhaarNumber: json['aadhaarNumber'] as String,
      panNumber: json['panNumber'] as String,
    );
  }
}

class ProfileData {
  final String fullName;
  final String cifId;
  final String mobileNumber;
  final String dateOfBirth;
  String emailId; // Mutable for local state updates
  String communicationAddress; // Mutable for local state updates
  final KycDetails kycDetails;
  final DateTime lastLoginTimestamp; // Added for completeness

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

  // Factory constructor to create a ProfileData object from a JSON map (API response structure)
  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      fullName: json['fullName'] as String,
      cifId: json['cifId'] as String,
      mobileNumber: json['mobileNumber'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      emailId: json['emailId'] as String,
      communicationAddress: json['communicationAddress'] as String,
      kycDetails: KycDetails.fromJson(json['kycDetails'] as Map<String, dynamic>),
      // MOCK: Assuming the API gives a string that needs parsing. Use current time for simplicity.
      lastLoginTimestamp: json.containsKey('lastLoginTimestamp')
          ? DateTime.parse(json['lastLoginTimestamp'] as String)
          : DateTime.now(),
    );
  }
}

// --- PROFILE SERVICE CLASS ---

/// Handles fetching (and potentially updating) user profile data.
class ProfileService {
  // Mock data representing the API response (Nominees removed)
  static final Map<String, dynamic> mockProfileJson = {
    'fullName': 'Aarav Sharma',
    'cifId': 'CIF10023456',
    'mobileNumber': '+91 98765 43210',
    'dateOfBirth': '20/05/1990',
    'emailId': 'aarav.sharma@example.com',
    'communicationAddress': 'Plot No. 12, Sector 15, Dwarka, New Delhi - 110078, India',
    'kycDetails': {
      'aadhaarNumber': 'XXXX XXXX 1234',
      'panNumber': 'ABCDE1234F',
    },
    'lastLoginTimestamp': '2025-11-27 09:30:00', // Mock ISO 8601 string format
  };

  /// Simulates fetching profile data from an API asynchronously.
  Future<ProfileData> fetchProfileData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    // Convert the mock JSON data into the structured ProfileData model
    return ProfileData.fromJson(mockProfileJson);
  }
}