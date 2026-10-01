import 'package:flutter/material.dart';
import '../services/sale.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _shiftIdController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _salesFuture;
  int? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _salesFuture = SaleService.getSales();
  }

  @override
  void dispose() {
    _shiftIdController.dispose();
    super.dispose();
  }

  void _loadSales({int? shiftId}) {
    setState(() {
      _selectedShiftId = shiftId;
      _salesFuture = SaleService.getSales(shiftId: shiftId);
    });
  }

  String _value(
    Map<String, dynamic> sale,
    List<String> keys, {
    String fallback = 'N/D',
  }) {
    for (final key in keys) {
      final value = sale[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shiftIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID de turno',
                    prefixIcon: Icon(Icons.tag),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _filterByShift(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Buscar ventas del turno',
                onPressed: _filterByShift,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Ver todas las ventas',
                onPressed: () {
                  _shiftIdController.clear();
                  _loadSales();
                },
                icon: const Icon(Icons.list_alt),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _salesFuture,
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
                        'No se pudieron cargar las ventas: ${snapshot.error}',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _loadSales(shiftId: _selectedShiftId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final sales = snapshot.data ?? [];
              if (sales.isEmpty) {
                return Center(
                  child: Text(
                    _selectedShiftId == null
                        ? 'No hay ventas disponibles'
                        : 'No hay ventas para el turno $_selectedShiftId',
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final items = sale['items'] ?? sale['products'];
                  final itemCount = items is List ? items.length : 0;
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long),
                      ),
                      title: Text(
                        'Venta #${_value(sale, ['saleId', 'sale_id', 'id'])}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Turno ${_value(sale, ['shiftId', 'shift_id', 'shiftid'])} · '
                        '${_value(sale, ['cashierusername', 'cashierUsername', 'cashierId'], fallback: 'Cajero N/D')}\n'
                        '${_value(sale, ['status'], fallback: 'Estado N/D')} · '
                        '${_value(sale, ['paymentMethod', 'payment_method'], fallback: 'Pago N/D')} · '
                        '$itemCount artículos\n'
                        '${_value(sale, ['createdAt', 'created_at'], fallback: 'Fecha N/D')}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        _money(sale['total']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _filterByShift() {
    final shiftId = int.tryParse(_shiftIdController.text.trim());
    if (shiftId == null || shiftId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un ID de turno válido.')),
      );
      return;
    }
    _loadSales(shiftId: shiftId);
  }
}
