import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart.dart';
import '../providers/auth_provider.dart';
import '../providers/shift_provider.dart';
import '../services/sale.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'Efectivo';
  String _cardType = 'DEBIT';
  final TextEditingController _amountGivenController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountGivenController.dispose();
    super.dispose();
  }

  void _processPayment(
    CartProvider cart,
    ShiftProvider shift,
    AuthProvider auth,
  ) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (cart.items.isEmpty) {
        _showSnackBar('El carrito esta vacio', Colors.red);
        return;
      }
      if (!shift.hasActiveShift || shift.activeShiftId == null) {
        _showSnackBar(
          'No hay un turno abierto. Debe abrir turno antes de cobrar.',
          Colors.red,
        );
        return;
      }
      if (!auth.isAuthenticated || auth.userUuid == null) {
        _showSnackBar(
          'Error de autenticacion. Inicie sesion nuevamente.',
          Colors.red,
        );
        return;
      }
      final double total = cart.total;
      if (total <= 0) {
        _showSnackBar(
          'El total de la venta debe ser mayor a cero.',
          Colors.red,
        );
        return;
      }

      final amountText = _amountGivenController.text.trim();
      double amountGiven = total;
      if (_paymentMethod == 'Efectivo') {
        if (amountText.isEmpty) {
          _showSnackBar('Ingresa el monto recibido', Colors.red);
          return;
        }

        final parsedAmount = double.tryParse(amountText);
        if (parsedAmount == null) {
          _showSnackBar('Ingresa un monto valido', Colors.red);
          return;
        }
        if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(amountText)) {
          _showSnackBar('El monto puede tener maximo 2 decimales', Colors.red);
          return;
        }
        if (parsedAmount > 9999) {
          _showSnackBar(
            'El monto recibido no puede ser mayor a 9999',
            Colors.red,
          );
          return;
        }
        if (parsedAmount < total) {
          _showSnackBar(
            'El monto recibido no puede ser menor al total',
            Colors.red,
          );
          return;
        }
        amountGiven = parsedAmount;
      }
      if (_paymentMethod == 'Tarjeta' && _cardType.isEmpty) {
        _showSnackBar(
          'Seleccione el tipo de tarjeta (Debito/Credito)',
          Colors.red,
        );
        return;
      }

      final double changeGiven = _paymentMethod == 'Efectivo'
          ? amountGiven - total
          : 0.0;
      final transactionReference = _paymentMethod == 'Tarjeta'
          ? _cardType
          : 'Efectivo';

      final result = await SaleService.processSale(
        shiftId: shift.activeShiftId!,
        cashierId: auth.cashierId ?? auth.userUuid ?? '',
        total: total,
        paymentMethod: _paymentMethod,
        amountGiven: amountGiven,
        changeGiven: changeGiven,
        transactionReference: transactionReference,
        products: cart.items,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await shift.refreshSalesSummary(auth.token!);
        if (mounted) {
          final shiftMgmt = context.read<ShiftProvider>();
          await shiftMgmt.refreshSalesSummary(auth.token!);
        }
        cart.clearCart();
        Navigator.of(context).pop();
        _showSnackBar(
          'Venta realizada con exito! Cambio: \$${changeGiven.toStringAsFixed(2)}',
          Colors.green,
        );
      } else {
        _showSnackBar(
          result['message'] ?? 'Error al realizar la venta',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String text, Color bg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF2B04E);
    final cart = context.watch<CartProvider>();
    final shift = context.watch<ShiftProvider>();
    final auth = context.watch<AuthProvider>();

    final double amountGiven =
        double.tryParse(_amountGivenController.text) ?? 0.0;
    final double change = amountGiven > cart.total
        ? amountGiven - cart.total
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: const Text(
          'Procesar Cobro',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('El carrito esta vacio'))
          : AbsorbPointer(
              absorbing: _isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return ListTile(
                            title: Text(
                              item.productName ?? 'Producto #${item.productId}',
                            ),
                            subtitle: Text(
                              '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () => cart.decrementQuantity(
                                          item.productId,
                                        ),
                                ),
                                IconButton(
                                  tooltip: 'Aumentar cantidad',
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () => cart.addProduct(
                                          id: item.productId,
                                          name: item.productName,
                                          price: item.unitPrice,
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Método de Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Efectivo',
                          label: Text('Efectivo'),
                          icon: Icon(Icons.payments),
                        ),
                        ButtonSegment(
                          value: 'Tarjeta',
                          label: Text('Tarjeta'),
                          icon: Icon(Icons.credit_card),
                        ),
                      ],
                      selected: {_paymentMethod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _paymentMethod = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_paymentMethod == 'Efectivo') ...[
                      TextField(
                        controller: _amountGivenController,
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
                        decoration: const InputDecoration(
                          labelText: 'Monto Recibido',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cambio:',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '\$${change.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: change >= 0
                                    ? Colors.green[700]
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: _cardType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Tarjeta',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'DEBIT',
                            child: Text('Debito'),
                          ),
                          DropdownMenuItem(
                            value: 'CREDIT',
                            child: Text('Credito'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _cardType = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${cart.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _processPayment(cart, shift, auth),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CONFIRMAR Y COBRAR',
                              style: TextStyle(
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
}
