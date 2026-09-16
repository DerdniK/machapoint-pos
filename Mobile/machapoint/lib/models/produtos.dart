class ProductType {
  final int typeId;
  final String typeName;

  ProductType({
    required this.typeId,
    required this.typeName,
  });
  static const Map<int, String> _typeMap = {
    1: 'posters',
    2: 'pines',
    3: 'stickers',
    4: 'postales',
  };
  String get typeNameResolved {
    if (_typeMap.containsKey(typeId)) {
      return _typeMap[typeId]!;
    }
    return typeName.isNotEmpty ? typeName : 'Tipo $typeId';
  }

  static int _parseId(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static dynamic _valueFor(Map<String, dynamic> json, List<String> names) {
    for (final entry in json.entries) {
      final normalizedKey = entry.key.toLowerCase().replaceAll('_', '');
      if (names.contains(normalizedKey)) return entry.value;
    }
    return null;
  }

  static dynamic _typeIdValue(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final normalizedKey = entry.key.toLowerCase().replaceAll('_', '');
      if (normalizedKey.endsWith('typeid') || normalizedKey.endsWith('tipoid')) {
        return entry.value;
      }
    }
    return null;
  }

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      typeId: _parseId(_valueFor(json, ['typeid', 'id'])),
      typeName: _valueFor(json, ['typename', 'name'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeId': typeId,
      'typeName': typeName,
    };
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
    final dynamic rawType = json['type'] ?? json['Type'];
    final Map<String, dynamic>? typeJson = rawType is Map
        ? Map<String, dynamic>.from(rawType)
        : null;
    final int extractedTypeId = ProductType._parseId(
      typeJson?['typeid'] ?? typeJson?['typeId'] ?? typeJson?['TypeId'],
    );

    return Product(
      productId: ProductType._parseId(json['productid'] ?? json['productId']),
      name: (json['name'] ?? json['Name'])?.toString() ?? '',
      sku: (json['sku'] ?? json['SKU'])?.toString() ?? '',
      type: ProductType(
        typeId: extractedTypeId,
        typeName: (typeJson?['typeName'] ?? typeJson?['typename'])?.toString() ?? '',
      ),
      price: ((json['price'] ?? json['Price']) as num?)?.toDouble() ?? 0.0,
      imageUrl: (json['imageURL'] ?? json['ImageURL'] ?? json['imageUrl'])
              ?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'sku': sku,
      'type': type?.toJson(),
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}