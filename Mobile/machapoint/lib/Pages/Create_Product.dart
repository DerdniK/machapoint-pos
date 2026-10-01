import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/product.dart';
import '../utils/pinterest_image_url.dart';
import '../utils/product_validation.dart';

class CreateProductPage extends StatefulWidget {
  final VoidCallback? onProductCreated;
  final bool showAppBar;

  const CreateProductPage({
    super.key,
    this.onProductCreated,
    this.showAppBar = true,
  });

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  int _selectedTypeId = 1;

  bool _isLoading = false;
  // 2. Método para limpiar los controladores, errores de validación y el estado
  void _clearForm() {
    _nameController.clear();
    _skuController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _selectedTypeId = 1;
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl = await PinterestImageUrl.resolve(
        _imageUrlController.text,
      );
      final success = await ProductService.createProduct(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        typeId: _selectedTypeId,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado con éxito'),
            backgroundColor: Colors.green,
          ),
        );

        // Se limpian los campos inmediatamente al guardar con éxito
        _clearForm();

        if (widget.onProductCreated != null) {
          widget.onProductCreated!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF2B04E);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: orangeColor,
              elevation: 0,
              title: const Text(
                'Crea tu nuevo producto',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nombre del producto (máximo 100 caracteres)',
                maxLength: 100,
                validator: ProductValidation.name,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _skuController,
                label: 'SKU (Máximo 20 caracteres)',
                maxLength: 20,
                validator: ProductValidation.sku,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Precio',
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
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedTypeId,
                decoration: InputDecoration(
                  labelText: 'Tipo de Producto',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Tipo 1 (Poster)')),
                  DropdownMenuItem(value: 2, child: Text('Tipo 2 (Pines)')),
                  DropdownMenuItem(value: 3, child: Text('Tipo 3 (Stickers)')),
                  DropdownMenuItem(value: 4, child: Text('Tipo 4 (Postales)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTypeId = val);
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imageUrlController,
                label: 'URL de la imagen (máximo 100 caracteres)',
                maxLength: 100,
                validator: ProductValidation.imageUrl,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Guardar Producto',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
