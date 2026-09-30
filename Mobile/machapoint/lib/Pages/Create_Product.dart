import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/product.dart';

class CreateProductPage extends StatefulWidget {
  final VoidCallback? onProductCreated;

  const CreateProductPage({super.key, this.onProductCreated});

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
  Future<String> _resolvePinterestUrl(String url) async {
    final trimmedUrl = url.trim();
    final lowerUrl = trimmedUrl.toLowerCase();

    if (lowerUrl.contains('i.pinimg.com') ||
        RegExp(r'\.(jpg|jpeg|png|webp)(\?.*)?$', caseSensitive: false)
            .hasMatch(lowerUrl)) {
      return trimmedUrl;
    }

    if (lowerUrl.contains('pin.it') || lowerUrl.contains('pinterest.com')) {
      try {
        final response = await http.get(
          Uri.parse(trimmedUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
          },
        );

        if (response.statusCode == 200) {
          final html = response.body;

          final regExp = RegExp(
            r'<meta[^>]*property=["'']og:image["''][^>]*content=["'']([^"'']+)["'']',
            caseSensitive: false,
          );
          final regExpAlt = RegExp(
            r'<meta[^>]*content=["'']([^"'']+)["''][^>]*property=["'']og:image["'']',
            caseSensitive: false,
          );

          final match = regExp.firstMatch(html) ?? regExpAlt.firstMatch(html);

          if (match != null && match.groupCount >= 1) {
            String imageUrl = match.group(1)!;
            return imageUrl.replaceAll(RegExp(r'/\d+x/'), '/originals/');
          }
        }
      } catch (_) {
      }
    }

    return trimmedUrl;
  }

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
      final imageUrl = await _resolvePinterestUrl(_imageUrlController.text);
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
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: const Text(
          'Crea tu nuevo producto',
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
                label: 'SKU (Máximo 20 caracteres)',
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
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final validFormat = RegExp(r'^\d*(\.\d{0,2})?$');
                    return validFormat.hasMatch(newValue.text) ? newValue : oldValue;
                  }),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo requerido';
                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(val.trim())) {
                    return 'Usa máximo 2 decimales';
                  }
                  final precioNum = double.tryParse(val.trim());
                  if (precioNum == null) return 'Ingresa un número válido';
                  if (precioNum <= 0) return 'El precio debe ser mayor a 0';
                  if (precioNum >= 500) return 'Nadie comprara algo tan caro';
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