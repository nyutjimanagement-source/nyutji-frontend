class LgWasherModel {
  final String deviceId;
  final String name;
  final String model;
  final bool isOn;
  final String status;
  final String remainTime;
  final String maintenance;

  LgWasherModel({
    required this.deviceId,
    required this.name,
    required this.model,
    required this.isOn,
    required this.status,
    required this.remainTime,
    required this.maintenance,
  });

  factory LgWasherModel.fromJson(Map<String, dynamic> json) {
    return LgWasherModel(
      deviceId: json['deviceId'] ?? '',
      name: json['name'] ?? 'Mesin LG',
      model: json['model'] ?? 'Unknown',
      isOn: json['isOn'] ?? false,
      status: json['status'] ?? 'UNKNOWN',
      remainTime: json['remainTime'] ?? '-',
      maintenance: json['maintenance'] ?? '-',
    );
  }
}
