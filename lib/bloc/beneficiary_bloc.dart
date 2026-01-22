import 'package:flutter_bloc/flutter_bloc.dart';
import '../api/beneficiary_api.dart';
import '../models/beneficiary_model.dart';

abstract class BeneficiaryEvent {}
class LoadList extends BeneficiaryEvent {}
class VerifyIFSC extends BeneficiaryEvent { final String acc, ifsc; VerifyIFSC(this.acc, this.ifsc); }
class SaveBeneficiary extends BeneficiaryEvent { final BeneficiaryModel data; final bool isEdit; SaveBeneficiary(this.data, this.isEdit); }
class DeleteBeneficiary extends BeneficiaryEvent { final String id; DeleteBeneficiary(this.id); }

class BeneficiaryState {
  final bool isLoading;
  final List<BeneficiaryModel> beneficiaries;
  final String? bankName;
  final String? officialName;
  final bool isSuccess;
  final String? error;

  BeneficiaryState({this.isLoading = false, this.beneficiaries = const [], this.bankName, this.officialName, this.isSuccess = false, this.error});

  BeneficiaryState copyWith({bool? isLoading, List<BeneficiaryModel>? beneficiaries, String? bankName, String? officialName, bool? isSuccess, String? error}) {
    return BeneficiaryState(
      isLoading: isLoading ?? this.isLoading,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      bankName: bankName ?? this.bankName,
      officialName: officialName ?? this.officialName,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class BeneficiaryBloc extends Bloc<BeneficiaryEvent, BeneficiaryState> {
  final BeneficiaryApi _api = BeneficiaryApi();

  BeneficiaryBloc() : super(BeneficiaryState()) {
    on<LoadList>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final list = await _api.getBeneficiaries();
      emit(state.copyWith(isLoading: false, beneficiaries: list));
    });

    on<VerifyIFSC>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final res = await _api.verifyBank(event.acc, event.ifsc);
      emit(state.copyWith(isLoading: false, bankName: res['bankName'], officialName: res['officialName']));
    });

    on<SaveBeneficiary>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      await _api.saveOrUpdate(event.data, event.isEdit);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    });

    on<DeleteBeneficiary>((event, emit) async {
      await _api.delete(event.id);
      add(LoadList());
    });
  }
}