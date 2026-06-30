class ChatMessageModel {
  final int id;
  final String orderNumber;
  final String channel;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.orderNumber,
    required this.channel,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? 0,
      orderNumber: json['orderNumber']?.toString() ??
          json['order_number']?.toString() ??
          '',
      channel: json['channel']?.toString() ?? '',
      senderId: json['senderId']?.toString() ??
          json['sender_id']?.toString() ??
          '',
      senderName: json['senderName']?.toString() ??
          json['sender_name']?.toString() ??
          '',
      senderRole: json['senderRole']?.toString() ??
          json['sender_role']?.toString() ??
          '',
      message: json['message']?.toString() ?? '',
      createdAt: () {
        final dateStr = (json['createdAt'] ?? json['created_at'])?.toString();
        if (dateStr == null) return DateTime.now();
        final parsed = DateTime.tryParse(dateStr) ?? DateTime.now();
        return parsed.toLocal();
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'channel': channel,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
