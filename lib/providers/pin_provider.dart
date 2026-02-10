import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class PinState {
  final bool isLoading;
  final String errorMessage;

  PinState({this.isLoading = false, this.errorMessage = ''});
}

class PinNotifier extends StateNotifier<PinState> {
  PinNotifier() : super(PinState());

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.0.102:8088',
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<bool> setTransactionPin(String accountNumber, String mpin) async {
    state = PinState(isLoading: true);
    try {
      final response = await _dio.post(
        '/api/transactions/create-transaction-mpin',
        queryParameters: {
          'accountNumber': accountNumber,
          'mpin': mpin,
        },
      );

      state = PinState(isLoading: false);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      state = PinState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final pinNotifierProvider = StateNotifierProvider<PinNotifier, PinState>((ref) => PinNotifier());