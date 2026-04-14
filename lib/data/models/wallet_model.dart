class WalletModel {
  final String userId;
  final double balance;

  WalletModel({
    required this.userId,
    required this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['userId'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
    };
  }
}
