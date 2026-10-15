class ProductType {
  final int typeId;
  final String typeName;

  ProductType({required this.typeId, required this.typeName});
  static const Map<int, String> _typeMap = {
    1: 'Posters',
    2: 'Pines',
    3: 'Stickers',
    4: 'Postales',
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
      if (normalizedKey.endsWith('typeid') ||
          normalizedKey.endsWith('tipoid')) {
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
    return {'typeId': typeId, 'typeName': typeName};
  }
}

class Product {
  final int productId;
  final String name;
  final String sku;
  final ProductType? type;
  final double price;
  final String imageUrl;
  final int? stock;

  Product({
    required this.productId,
    required this.name,
    required this.sku,
    this.type,
    required this.price,
    required this.imageUrl,
    this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final normalized = {
      for (final entry in json.entries)
        entry.key.toLowerCase().replaceAll('_', ''): entry.value,
    };
    final dynamic rawType = json['type'] ?? json['Type'];
    final Map<String, dynamic>? typeJson = rawType is Map
        ? Map<String, dynamic>.from(rawType)
        : null;
    final normalizedType = typeJson == null
        ? <String, dynamic>{}
        : {
            for (final entry in typeJson.entries)
              entry.key.toLowerCase().replaceAll('_', ''): entry.value,
          };
    final int extractedTypeId = ProductType._parseId(
      normalizedType['typeid'] ??
          normalizedType['id'] ??
          normalized['typeid'] ??
          normalized['tipoid'],
    );

    return Product(
      productId: ProductType._parseId(
        normalized['productid'] ?? normalized['id'],
      ),
      name: (json['name'] ?? json['Name'])?.toString() ?? '',
      sku: (json['sku'] ?? json['SKU'])?.toString() ?? '',
      type: ProductType(
        typeId: extractedTypeId,
        typeName:
            (normalizedType['typename'] ??
                    normalizedType['name'] ??
                    normalized['typename'] ??
                    normalized['type'])
                ?.toString() ??
            '',
      ),
      price: ((json['price'] ?? json['Price']) as num?)?.toDouble() ?? 0.0,
      imageUrl:
          (json['imageURL'] ?? json['ImageURL'] ?? json['imageUrl'])
              ?.toString() ??
          '',
      stock: _parseStock(
        normalized['stock'] ??
            normalized['quantity'] ??
            normalized['inventorystock'],
      ),
    );
  }

  static int? _parseStock(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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
