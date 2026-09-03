class ProductType {
  final int typeId;
  final String typeName;

  ProductType({
    required this.typeId,
    required this.typeName,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      typeId: (json['typeId'] as num?)?.toInt() ?? 0,
      typeName: json['typeName']?.toString() ?? '',
    );
  }
}

class Product {
  final int productId;
  final String name;
  final String sku;
  final ProductType? type;
  final double price;
  final String imageUrl;

  Product({
    required this.productId,
    required this.name,
    required this.sku,
    this.type,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      type: json['type'] != null ? ProductType.fromJson(json['type']) : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageURL']?.toString() ?? json['imageUrl']?.toString() ?? '',
    );
  }
}