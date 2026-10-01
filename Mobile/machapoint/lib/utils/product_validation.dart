class ProductValidation {
  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Campo requerido';
    if (name.length > 100) return 'El nombre no puede superar 100 caracteres';
    return null;
  }

  static String? sku(String? value) {
    final sku = value?.trim() ?? '';
    if (sku.isEmpty) return 'Campo requerido';
    if (sku.length > 20) return 'El SKU no puede superar 20 caracteres';
    return null;
  }

  static String? imageUrl(String? value) {
    final imageUrl = value?.trim() ?? '';
    if (imageUrl.isEmpty) return 'Campo requerido';
    if (imageUrl.length > 100) {
      return 'La URL no puede superar 100 caracteres';
    }
    return null;
  }

  static String? price(String? value) {
    final priceText = value?.trim() ?? '';
    if (priceText.isEmpty) return 'Campo requerido';
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(priceText)) {
      return 'Usa máximo 2 decimales';
    }
    final price = double.tryParse(priceText);
    if (price == null) return 'Ingresa un número válido';
    if (price <= 0) return 'El precio debe ser mayor a 0';
    if (price > 500) return 'El precio no puede ser mayor a 500, nadie compra algo tan caro';
    return null;
  }
}
