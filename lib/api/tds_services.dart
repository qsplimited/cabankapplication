// File: lib/api/tds_service.dart

import 'dart:async';

class TdsService { // Finalized class name
  /// API to request/download the TDS Certificate for a given financial year.
  /// Used '123456' as the mock valid TPIN.
  Future<Map<String, dynamic>> tdsCertificateRequest({
    required String accountId,
    required String financialYear,
    required String tpin,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // --- TPIN Authentication Check ---
    if (tpin != '123456') { // TPIN must match '123456' exactly
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'status': 'error',
        'message': '❌ Invalid TPIN. Please verify your 6-digit Transaction PIN.',
      };
    }

    // --- Business Logic Simulation (Success/Failure based on year) ---
    if (financialYear == '2022-2023' || financialYear == '2024-2025') {
      // SUCCESS: Download is ready
      return {
        'status': 'success',
        'message': 'TDS Certificate for FY $financialYear is ready for download. Check your device\'s notification/downloads.',
        'download_url': 'https://bank.com/docs/tds_cert_${financialYear.replaceAll('/', '-')}.pdf',
        'password_hint': 'Password is the first 4 letters of your PAN (CAPS) + Date of Birth (DDMMYYYY).',
        'file_type': 'PDF',
      };
    } else if (financialYear == '2023-2024') {
      return {
        'status': 'error',
        'message': 'TDS Certificate for FY $financialYear is not yet available. Please check again after 15th June.',
      };
    } else {
      return {
        'status': 'error',
        'message': 'Invalid selection. Please try a different year.',
      };
    }
  }
}