// File: lib/services/nominee_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/nominee_model.dart';

/// A mock service to simulate fetching and updating nominee data from a backend.
class NomineeService {
  // Mock data store
  static final List<NomineeModel> _mockNominees = [
    NomineeModel(
      id: 'N001',
      fullName: 'Aisha Sharma',
      relationship: 'Spouse',
      sharePercentage: 60.0,
      accountType: 'Savings',
    ),
    NomineeModel(
      id: 'N002',
      fullName: 'Rohit Sharma',
      relationship: 'Son',
      sharePercentage: 40.0,
      accountType: 'Savings',
    ),
    NomineeModel(
      id: 'N003',
      fullName: 'Priya Verma',
      relationship: 'Daughter',
      sharePercentage: 100.0,
      accountType: 'Fixed Deposit',
    ),
  ];

  /// Simulates fetching nominees for a given account type.
  /// Returns a Future that completes with the list of NomineeModel objects.
  Future<List<NomineeModel>> fetchNomineesByAccountType(String accountType) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    final result = _mockNominees
        .where((n) => n.accountType == accountType)
        .toList();

    if (result.isEmpty) {
      throw Exception('No nominees found for account type: $accountType');
    }

    return result;
  }

  /// Simulates updating a nominee's details.
  /// In a real app, this would involve a PUT or PATCH API call.
  Future<NomineeModel> updateNominee(NomineeModel updatedNominee) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _mockNominees.indexWhere((n) => n.id == updatedNominee.id);

    if (index != -1) {
      _mockNominees[index] = updatedNominee;
      debugPrint('Nominee updated: ${updatedNominee.fullName}');
      return updatedNominee;
    } else {
      throw Exception('Nominee with ID ${updatedNominee.id} not found for update.');
    }
  }
}