import 'package:MachaPoint/Pages/Cart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produtos.dart';
import '../providers/cart.dart';
import '../services/auth.dart';
import '../services/product.dart';
import 'Login_Page.dart';
import 'create_user_page.dart'; 
import 'Create_product.dart';
import 'turns_man.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _currentIndex = 0;
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchProductsWithRetry();
  }

  Future<List<Product>> _fetchProductsWithRetry() async {
    int retries = 0;
    while (retries < 3) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        return await ProductService.getProducts();
      }
      await Future.delayed(const Duration(milliseconds: 300));
      retries++;
    }
    return await ProductService.getProducts();
  }

  void _refreshProducts() {
    setState(() {
      _futureProducts = _fetchProductsWithRetry();
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'MachaPoint POS';
      case 1:
        return 'Crear Producto';
      case 2:
        return 'Usuarios';
      case 3:
        return 'Gestión de Turno';
      default:
        return 'MachaPoint POS';
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF2B04E);
    final List<Widget> pages = [
      _buildProductGrid(),
      CreateProductPage(
        onProductCreated: () {
          _refreshProducts();
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const CreateUserPage(),
      const ShiftManagementPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              await AuthService.logout();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          if (_currentIndex == 0) _buildCartBottomBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: orangeColor,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Crear Producto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Turno',
          ),
        ],
      ),
    );
  }

  Widget _buildCartBottomBar() {
  return Consumer<CartProvider>(
    builder: (context, cart, child) {
      if (cart.items.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.itemCount} ${cart.itemCount == 1 ? "producto" : "productos"}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                Text(
                  '\$${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2B04E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_checkout, color: Colors.black),
              label: const Text(
                'COBRAR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutPage(
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildProductGrid() {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF2B04E),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sin conexión a internet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Comprueba tu conexión de red e inténtalo de nuevo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2B04E),
                      foregroundColor: Colors.black,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _refreshProducts,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text(
                      'Reintentar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.48, // Ajustado para dar espacio al botón
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          );
        }

        return const Center(child: Text('No hay productos disponibles'));
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFF2B04E);

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartItemIndex = cart.items.indexWhere((item) => item.productId == product.productId);
        final currentQuantity = cartItemIndex != -1 ? cart.items[cartItemIndex].quantity : 0;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del producto
                  Center(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Imagen del producto
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported, color: Colors.grey),
                              )
                            : const Icon(Icons.inventory_2, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // SKU
                  Text(
                    'SKU: ${product.sku}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Categoría
                  Text(
                    product.type?.typeNameResolved ?? 'Sin categoría',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Precio
                  Text(
                    'Precio: \$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Botón Agregar
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        cart.addProduct(
                          id: product.productId,
                          name: product.name,
                          price: product.price,
                        );

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} agregado'),
                            duration: const Duration(milliseconds: 600),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Agregar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        );
      },
    );
  }
}