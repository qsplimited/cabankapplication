import '../models/beneficiary_model.dart';

class BeneficiaryApi {
  // STATIC: This ensures the 3 initial data cases stay even when you navigate away
  static final List<Beneficiary> _mockDb = [
    Beneficiary(
      beneficiaryId: 'BENF1',
      name: 'Jane Doe',
      accountNumber: '987654321098',
      ifsCode: 'HDFC0000053',
      bankName: 'HDFC Bank',
      nickname: 'Jane (Rent)',
    ),
    Beneficiary(
      beneficiaryId: 'BENF2',
      name: 'John Smith',
      accountNumber: '112233445566',
      ifsCode: 'ICIC0001234',
      bankName: 'ICICI Bank',
      nickname: 'John (Utilities)',
    ),
    Beneficiary(
      beneficiaryId: 'BENF3',
      name: 'Alice Williams',
      accountNumber: '556677889900',
      ifsCode: 'SBIN0001234',
      bankName: 'State Bank of India',
      nickname: 'Alice (Gym)',
    ),
  ];

  Future<List<Beneficiary>> fetchBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_mockDb);
  }

  Future<Map<String, dynamic>> verifyIFSC(String ifsc) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock logic from your banking_service.dart
    if (ifsc.toUpperCase().startsWith('HDFC')) return {'bankName': 'HDFC Bank'};
    if (ifsc.toUpperCase().startsWith('ICIC')) return {'bankName': 'ICICI Bank'};
    return {'bankName': 'Global Digital Bank'};
  }

  void addLocal(Beneficiary b) => _mockDb.add(b);

  void updateLocal(String id, Beneficiary b) {
    final index = _mockDb.indexWhere((e) => e.beneficiaryId == id);
    if (index != -1) _mockDb[index] = b;
  }

  void deleteLocal(String id) => _mockDb.removeWhere((e) => e.beneficiaryId == id);

  String maskAccountNumber(String acc) {
    if (acc.length < 4) return acc;
    return 'XXXX-XXXX-${acc.substring(acc.length - 4)}';
  }
}