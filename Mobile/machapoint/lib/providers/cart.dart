import 'package:flutter/material.dart';
import '../services/sale.dart';

class CartProvider extends ChangeNotifier {
  static const int maxQuantityPerProduct = CartItem.maximumQuantity;

  static String quantityLimitMessageForStock(int? availableStock) {
    if (availableStock != null &&
        availableStock < maxQuantityPerProduct) {
      return 'No hay mas disponibles de este producto.';
    }
    return 'No puedes agregar más de $maxQuantityPerProduct unidades del mismo producto.';
  }

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  bool addProduct({
    required int id,
    String? name,
    String imageUrl = '',
    int? availableStock,
    required double price,
  }) {
    final index = _items.indexWhere((item) => item.productId == id);

    if (index >= 0) {
      final item = _items[index];
      if (availableStock != null) item.availableStock = availableStock;
      if (item.quantity >= item.quantityLimit) return false;
      if (item.quantity >= maxQuantityPerProduct) return false;
      item.quantity++;
    } else {
      final item = CartItem(
        productId: id,
        productName: name,
        imageUrl: imageUrl,
        unitPrice: price,
        availableStock: availableStock,
        quantity: 1,
      );
      if (item.quantity > item.quantityLimit) return false;
      _items.add(item);
    }
    notifyListeners();
    return true;
  }

  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
