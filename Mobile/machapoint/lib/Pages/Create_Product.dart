import 'package:flutter/material.dart';
import '../services/product.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ProductService.createProduct(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        typeId: _selectedTypeId,
        imageUrl: _imageUrlController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado con exito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: const Text(
          'Crear Producto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nombre del producto',
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _skuController,
                label: 'SKU (Maximo 20 caracteres)',
                maxLength: 20, 
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo requerido';
                  if (val.length > 20) return 'El SKU no puede superar 20 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Precio',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo requerido';
                  final precioNum = double.tryParse(val.trim());
                  if (precioNum == null) return 'Ingresa un numero valido';
                  if (precioNum <= 0) return 'El precio debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTypeId,
                decoration: InputDecoration(
                  labelText: 'Tipo de Producto',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Tipo 1')),
                  DropdownMenuItem(value: 2, child: Text('Tipo 2')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTypeId = val);
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imageUrlController,
                label: 'URL de la imagen',
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Guardar Producto',
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
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