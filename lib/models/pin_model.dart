class PinModel {
  final dynamic value;
  final String message;
  final String httpCode;

  PinModel({
    this.value,
    required this.message,
    required this.httpCode,
  });

  factory PinModel.fromJson(Map<String, dynamic> json) {
    return PinModel(
      value: json['value'],
      message: json['message'] ?? "",
      httpCode: json['httpCode'] ?? "",
    );
  }
}