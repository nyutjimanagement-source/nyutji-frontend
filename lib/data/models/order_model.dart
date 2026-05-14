class OrderModel {
  final String orderNumber;
  final double totalPrice;
  final String status;
  final List<OrderItem> items;

  OrderModel({
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderNumber: json['order_number'],
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'],
      items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    );
  }
}

class OrderItem {
  final String itemName;
  final int qty;

  OrderItem({required this.itemName, required this.qty});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(itemName: json['item_name'], qty: json['qty']);
  }
}
