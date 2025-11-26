// File: lib/services/profile_service.dart

import 'package:flutter/material.dart'; // Used for Future/Duration, though imports should usually be minimal
import '../models/profile_model.dart';

/// Handles fetching (and potentially updating) user profile data.
class ProfileService {
  // Mock data representing the API response
  static final Map<String, dynamic> mockProfileJson = {
    'fullName': 'Kamal K N',
    'cifId': '2698889370',
    'userId': 'createUserId',
    'emailId': 'kamal.kn@gmail.com',
    'mobileNumber': '98765XXXX8',
    'dateOfBirth': '18-05-19XX',
    'communicationAddress': 'DEX CO WORK, NO 1383 433 5TH BLOCK, NAGAVARA, BANGALORE, INDIA 560045',
    'kycDetails': {
      'aadhaarNumber': 'XXXX XXXX 1234',
      'panNumber': 'GBJXXXX123D',
    },
    'nominees': [
      {'name': 'Shalini K', 'relationship': 'Mother', 'sharePercentage': 60.0},
      {'name': 'Arjun N', 'relationship': 'Father', 'sharePercentage': 40.0},
    ],
  };

  /// Simulates fetching profile data from an API asynchronously.
  /// In a real app, this would use http to fetch data.
  Future<ProfileData> fetchProfileData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Convert the mock JSON data into the structured ProfileData model
    return ProfileData.fromJson(mockProfileJson);
  }
}