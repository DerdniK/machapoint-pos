class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
  });
  double get subtotal => unitPrice * quantity;
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}