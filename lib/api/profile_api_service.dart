import '../models/profile_model.dart';

class ProfileApiService {
  // Mock JSON data representing what your API will return
  static final Map<String, dynamic> _mockProfileJson = {
    'fullName': 'Aarav Sharma',
    'cifId': 'CIF10023456',
    'mobileNumber': '+91 98765 43210',
    'dateOfBirth': '20/05/1990',
    'emailId': 'aarav.sharma@example.com',
    'communicationAddress': 'Plot No. 12, Sector 15, Dwarka, New Delhi - 110078',
    'kycDetails': {
      'aadhaarNumber': 'XXXX XXXX 1234',
      'panNumber': 'ABCDE1234F',
    },
    'lastLoginTimestamp': '2025-11-27T09:30:00',
  };

  /// Fetch profile from API
  Future<ProfileData> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    return ProfileData.fromJson(_mockProfileJson);
  }

  /// Update a specific field via API (e.g., PUT /profile/update)
  Future<bool> updateField(String fieldKey, String value) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real API: return response.statusCode == 200;
    return true;
  }
}