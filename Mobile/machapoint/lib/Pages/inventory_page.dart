import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produtos.dart';
import '../services/product.dart';
import '../utils/pinterest_image_url.dart';
import '../utils/product_validation.dart';
import 'Create_product.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const _createMode = 'Crear Producto';
  static const _editMode = 'Editar producto';

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _selectedMode = _createMode;
  String _searchQuery = '';
  late Future<List<Product>> _allProductsFuture;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _allProductsFuture = ProductService.getProducts();
    _productsFuture = _allProductsFuture;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshProducts() {
    setState(() {
      _allProductsFuture = ProductService.getProducts();
      _productsFuture = _allProductsFuture.then(
        (products) =>
            ProductService.filterProductsByQuery(products, _searchQuery),
      );
    });
  }

  void _searchProducts(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.trim();
        _productsFuture = _allProductsFuture.then(
          (products) =>
              ProductService.filterProductsByQuery(products, _searchQuery),
        );
      });
    });
  }

  Future<void> _editProduct(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku);
    final imageUrlController = TextEditingController(text: product.imageUrl);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    var selectedTypeId = product.type?.typeId ?? 1;
    if (selectedTypeId < 1 || selectedTypeId > 4) selectedTypeId = 1;
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Editar producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (máximo 100 caracteres)',
                    ),
                    validator: ProductValidation.name,
                  ),
                  TextFormField(
                    controller: skuController,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'SKU (máximo 20 caracteres)',
                    ),
                    validator: ProductValidation.sku,
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final validFormat = RegExp(r'^\d*(\.\d{0,2})?$');
                        return validFormat.hasMatch(newValue.text)
                            ? newValue
                            : oldValue;
                      }),
                    ],
                    validator: ProductValidation.price,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: selectedTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de producto',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Tipo 1 (Poster)'),
                      ),
                      DropdownMenuItem(value: 2, child: Text('Tipo 2 (Pines)')),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Tipo 3 (Stickers)'),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('Tipo 4 (Postales)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedTypeId = value);
                      }
                    },
                  ),
                  TextFormField(
                    controller: imageUrlController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'URL de imagen (máximo 100 caracteres)',
                    ),
                    validator: ProductValidation.imageUrl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true || !mounted) {
      nameController.dispose();
      skuController.dispose();
      imageUrlController.dispose();
      priceController.dispose();
      return;
    }
    try {
      final imageUrl = await PinterestImageUrl.resolve(imageUrlController.text);
      final updated = await ProductService.updateProduct(
        productId: product.productId,
        name: nameController.text.trim(),
        sku: skuController.text.trim(),
        imageUrl: imageUrl,
        price: double.parse(priceController.text),
        typeId: selectedTypeId,
      );
      if (updated && mounted) {
        _refreshProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado con éxito.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el producto: $error')),
        );
      }
    } finally {
      nameController.dispose();
      skuController.dispose();
      imageUrlController.dispose();
      priceController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedMode,
              decoration: const InputDecoration(
                labelText: 'Acción de inventario',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.black26),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: _createMode, child: Text(_createMode)),
                DropdownMenuItem(value: _editMode, child: Text(_editMode)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedMode = value);
                if (value == _editMode) _refreshProducts();
              },
            ),
          ),
          Expanded(
            child: _selectedMode == _createMode
                ? CreateProductPage(
                    showAppBar: false,
                    onProductCreated: () {
                      _refreshProducts();
                      setState(() => _selectedMode = _editMode);
                    },
                  )
                : _buildProducts(),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _searchProducts,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o SKU',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchProducts('');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No se pudieron cargar los productos: ${snapshot.error}',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _refreshProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No hay productos disponibles'
                        : 'No se encontraron productos',
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.48,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) => InventoryProductCard(
                  product: products[index],
                  onEdit: () => _editProduct(products[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2B04E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.inventory_2, color: Colors.grey)
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'SKU: ${product.sku}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          Text(
            product.type?.typeNameResolved ?? 'Sin categoría',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'Precio: \$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Editar', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
