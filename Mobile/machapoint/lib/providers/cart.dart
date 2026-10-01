import 'package:flutter/material.dart';
import '../services/sale.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);  
  void addProduct({
    required int id,
    String? name,
    required double price,
  }) {
    final index = _items.indexWhere((item) => item.productId == id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(
          productId: id,
          productName: name,
          unitPrice: price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
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