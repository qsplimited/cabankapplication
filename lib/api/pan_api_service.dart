// File: lib/api/pan_api_service.dart (Hypothetical path)

import 'package:flutter/material.dart';

class PanApiService {
  // Hardcoded T-PIN for mock success
  static const String _mockSuccessTpin = "123456";
  // Mock PAN that is already registered with another user (Fails business rule)
  static const String _mockRegisteredPan = "ZYXWV9876U";
  // Mock PAN that fails the Identity/Name match check (Fails core security)
  static const String _mockNameMismatchPan = "PANID1234A";

  // Simulates an API call delay and response
  Future<Map<String, dynamic>> updatePan({
    required String oldPan,
    required String newPan,
    required String tpin,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // 1. T-PIN Security Check (Authorization)
    if (tpin != _mockSuccessTpin) {
      return {
        "status": "ERROR",
        "message": "Invalid T-PIN. Security authorization failed. Please try again.",
        "errorCode": "ERR_T001",
      };
    }

    // --- CRUCIAL: Identity/Name Match Check (Simulates external authority check) ---
    if (newPan.toUpperCase() == _mockNameMismatchPan) {
      return {
        "status": "ERROR",
        "message": "Verification failed. The name on the new PAN does not match the name associated with this bank account.",
        "errorCode": "ERR_ID001",
      };
    }

    // 2. Business Rule Check (New PAN already registered)
    if (newPan.toUpperCase() == _mockRegisteredPan) {
      return {
        "status": "ERROR",
        "message": "The new PAN ID you entered is already registered with another user. Please check the details.",
        "errorCode": "ERR_P003",
      };
    }

    // 3. Prevent self-update to the same PAN
    if (newPan.toUpperCase() == oldPan.toUpperCase()) {
      return {
        "status": "ERROR",
        "message": "New PAN cannot be the same as the current PAN.",
        "errorCode": "ERR_P002",
      };
    }

    // Success Case (after all checks)
    return {
      "status": "SUCCESS",
      "message": "PAN update has been completed successfully.",
      "data": {"newPan": newPan.toUpperCase()},
    };
  }
}