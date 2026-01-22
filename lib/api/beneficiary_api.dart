import 'dart:async';
import '../models/beneficiary_model.dart';

class BeneficiaryApi {
  // Shared mock database for the module
  static final List<BeneficiaryModel> _mockData = [];

  Future<List<BeneficiaryModel>> getBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockData);
  }

  Future<Map<String, String>> verifyBank(String acc, String ifsc) async {
    await Future.delayed(const Duration(seconds: 1));
    // Extracted logic: Determine bank from IFSC
    String bank = "STATE BANK OF INDIA";
    if (ifsc.toUpperCase().startsWith('HDFC')) bank = "HDFC BANK";
    else if (ifsc.toUpperCase().startsWith('ICIC')) bank = "ICICI BANK";

    return {'bankName': bank, 'officialName': 'VERIFIED RECIPIENT'};
  }

  Future<void> saveOrUpdate(BeneficiaryModel data, bool isEdit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (isEdit) {
      final index = _mockData.indexWhere((e) => e.id == data.id);
      if (index != -1) _mockData[index] = data;
    } else {
      _mockData.insert(0, data);
    }
  }

  Future<void> delete(String id) async {
    _mockData.removeWhere((e) => e.id == id);
  }
}