import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/shift_provider.dart';
import '../services/sale.dart';
import 'package:MachaPoint/providers/auth_provider.dart';

class ShiftManagementPage extends StatefulWidget {
  const ShiftManagementPage({super.key});

  @override
  State<ShiftManagementPage> createState() => _ShiftManagementPageState();
}

class _ShiftManagementPageState extends State<ShiftManagementPage> {
  final TextEditingController _initialCashController = TextEditingController();
  final TextEditingController _actualCashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  Map<String, dynamic>? _zCutData;
  bool _loadingCut = false;
  double _lastInitialCash = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingShift();
    });
  }

  Future<void> _checkExistingShift() async {
    final authProvider = context.read<AuthProvider>();
    final shiftProvider = context.read<ShiftProvider>();

    if (authProvider.token == null) return;

    final cashierId = authProvider.cashierId ?? authProvider.userUuid ?? '';
    await shiftProvider.checkActiveShift(
      token: authProvider.token!,
      cashierId: cashierId,
    );

    if (!mounted) return;

    if (shiftProvider.hasActiveShift) {
      await shiftProvider.refreshSalesSummary(authProvider.token!);
      if (!mounted) return;
      setState(() {
        _lastInitialCash = shiftProvider.initialCash;
      });
    }
  }

  @override
  void dispose() {
    _initialCashController.dispose();
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchZCut(int shiftId, String token) async {
    if (!mounted) return;
    setState(() => _loadingCut = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws/api/cut/zcuts?shiftId=$shiftId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cuts = data['cuts'];
        final firstCut = cuts is List && cuts.isNotEmpty ? cuts.first : null;
        if (firstCut is Map) {
          setState(() => _zCutData = Map<String, dynamic>.from(firstCut));
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo Corte Z: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingCut = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    DateTime? parsed;
    if (value is DateTime) {
      parsed = value;
    } else {
      final strValue = value.toString().trim();
      if (strValue.isEmpty) return 'N/A';
      parsed = DateTime.tryParse(
        strValue.endsWith('Z') ? strValue : '${strValue}Z',
      );
    }
    if (parsed == null) return 'N/A';
    final localDate = parsed.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  String _formatMoney(dynamic value, {double fallback = 0.0}) {
    final parsedValue = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? fallback;
    return '\$${parsedValue.toStringAsFixed(2)}';
  }

  double _extractInitialCash() {
    if (_zCutData != null) {
      final rawValue =
          _zCutData!['initial_cash'] ??
          _zCutData!['initialCash'] ??
          _zCutData!['opening_cash'] ??
          _zCutData!['openingCash'] ??
          _zCutData!['opening_amount'] ??
          _zCutData!['openingAmount'];

      if (rawValue != null) {
        final parsed = double.tryParse(rawValue.toString());
        if (parsed != null && parsed >= 0) return parsed;
      }
    }
    return _lastInitialCash;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF2B04E);
    final shiftProvider = context.watch<ShiftProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      appBar: AppBar(
        title: const Text(
          'Gestión de Turno',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: orangeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!shiftProvider.hasActiveShift) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay un turno activo. Inicia uno para poder cobrar.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _initialCashController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[\.,]?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fondo Inicial en Caja',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: shiftProvider.isLoading
                    ? null
                    : () async {
                        final rawCash = _initialCashController.text.trim();
                        if (rawCash.isEmpty) {
                          _showMessage('Por favor, ingresa el fondo inicial.');
                          return;
                        }

                        final normalizedCash = rawCash.replaceAll(',', '.');
                        final cash = double.tryParse(normalizedCash);
                        if (cash == null || cash < 1 || cash > 99999) {
                          _showMessage('Ingresa un monto válido.');
                          return;
                        }

                        final cashierId =
                            authProvider.cashierId ??
                            authProvider.userUuid ??
                            '';
                        debugPrint(
                          '>>> Abriendo turno con cashierId: $cashierId (authProvider.userUuid: ${authProvider.userUuid})',
                        );

                        if (cashierId.isEmpty) {
                          _showMessage(
                            'No se pudo identificar al cajero autenticado',
                            isError: true,
                          );
                          return;
                        }

                        final ok = await shiftProvider.openShift(
                          token: authProvider.token ?? '',
                          cashierId: cashierId,
                          initialCash: cash,
                        );

                        if (!mounted) return;

                        if (ok) {
                          setState(() {
                            _lastInitialCash = cash;
                            _initialCashController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Turno abierto con éxito'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          _showMessage(
                            shiftProvider.errorMessage ??
                                'No se pudo abrir el turno',
                            isError: true,
                          );
                        }
                      },
                child: shiftProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'ABRIR TURNO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turno Activo ID: #${shiftProvider.activeShiftId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nombre del cajero: ${authProvider.userName ?? 'N/A'}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fondo Inicial: \$${shiftProvider.initialCash.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha inicio: ${_formatDate(shiftProvider.openedAt)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ActiveShiftSalesSection(
                key: ValueKey(shiftProvider.activeShiftId),
                shiftId: shiftProvider.activeShiftId!,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _actualCashController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[\.,]?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fondo final en Caja al Cerrar',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                maxLength: 280,
                inputFormatters: [LengthLimitingTextInputFormatter(280)],
                decoration: const InputDecoration(
                  labelText: 'Notas del Cierre / Observaciones',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: shiftProvider.isLoading
                    ? null
                    : () async {
                        final rawCash = _actualCashController.text.trim();
                        final cash = double.tryParse(
                          rawCash.replaceAll(',', '.'),
                        );
                        if (cash == null || cash < 0) {
                          _showMessage('Ingresa un monto final válido.');
                          return;
                        }
                        if (cash > 20000) {
                          _showMessage('El monto máximo son \$20,000.00.');
                          return;
                        }

                        _lastInitialCash = shiftProvider.initialCash;

                        final res = await shiftProvider.closeShift(
                          token: authProvider.token ?? '',
                          cashierId:
                              authProvider.cashierId ??
                              authProvider.userUuid ??
                              '',
                          actualCash: cash,
                          notes: _notesController.text,
                        );

                        if (!mounted) return;

                        if (res['success'] == true) {
                          final closedShiftId = res['shiftId'];
                          _actualCashController.clear();
                          _notesController.clear();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Turno cerrado correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          await _fetchZCut(
                            closedShiftId,
                            authProvider.token ?? '',
                          );
                        } else {
                          _showMessage(
                            res['message'] ?? 'Error al cerrar',
                            isError: true,
                          );
                        }
                      },
                child: shiftProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CERRAR TURNO Y GENERAR CORTE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
            if (_loadingCut)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_zCutData != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Resumen Corte Z',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Builder(
                    builder: (context) {
                      final double initialCash = _extractInitialCash();
                      final double totalSales =
                          double.tryParse(
                            (_zCutData!['totalSales'] ??
                                    _zCutData!['total_sales'] ??
                                    shiftProvider.totalSales)
                                .toString(),
                          ) ??
                          0.0;

                      final double expectedCash = initialCash + totalSales;
                      final double actualCash =
                          double.tryParse(
                            (_zCutData!['actualCash'] ??
                                    _zCutData!['actual_cash'])
                                .toString(),
                          ) ??
                          0.0;

                      final double difference = actualCash - expectedCash;
                      String statusText;
                      Color statusColor;
                      if (difference < -0.01) {
                        statusText = 'FALTANTE';
                        statusColor = Colors.red;
                      } else if (difference > 0.01) {
                        statusText = 'SOBRANTE';
                        statusColor = Colors.green;
                      } else {
                        statusText = 'EXACTO';
                        statusColor = Colors.blue;
                      }
                      String formattedDifference;
                      if (difference < -0.01) {
                        formattedDifference =
                            '-\$${difference.abs().toStringAsFixed(2)}';
                      } else if (difference > 0.01) {
                        formattedDifference =
                            '+\$${difference.toStringAsFixed(2)}';
                      } else {
                        formattedDifference = '\$0.00';
                      }

                      return Column(
                        children: [
                          _buildCutRow(
                            'Nombre del Cajero:',
                            _zCutData!['cashierName'] ??
                                _zCutData!['cashier_name'] ??
                                _zCutData!['cashier']?['name'] ??
                                authProvider.userName ??
                                'N/A',
                          ),
                          _buildCutRow(
                            'ID de Turno:',
                            '${_zCutData!['shiftId'] ?? shiftProvider.activeShiftId ?? 'N/A'}',
                          ),
                          _buildCutRow(
                            'Fecha Inicio:',
                            _formatDate(
                              _zCutData!['openedAt'] ?? _zCutData!['opened_at'],
                            ),
                          ),
                          _buildCutRow(
                            'Fecha Final:',
                            _formatDate(
                              _zCutData!['closedAt'] ?? _zCutData!['closed_at'],
                            ),
                          ),
                          const Divider(height: 20),
                          _buildCutRow(
                            'Monto inicial:',
                            _formatMoney(initialCash),
                          ),
                          _buildCutRow(
                            'Ventas del Turno:',
                            _formatMoney(totalSales),
                          ),
                          _buildCutRow(
                            'Monto esperado:',
                            _formatMoney(expectedCash),
                          ),
                          _buildCutRow('Monto real:', _formatMoney(actualCash)),
                          _buildCutRow(
                            'Diferencia:',
                            formattedDifference,
                            valueColor: statusColor,
                          ),
                          _buildCutRow(
                            'Estado:',
                            statusText,
                            valueColor: statusColor,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCutRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftSalesSection extends StatefulWidget {
  final int shiftId;

  const _ActiveShiftSalesSection({super.key, required this.shiftId});

  @override
  State<_ActiveShiftSalesSection> createState() =>
      _ActiveShiftSalesSectionState();
}

class _ActiveShiftSalesSectionState extends State<_ActiveShiftSalesSection> {
  late Future<List<Map<String, dynamic>>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _salesFuture = SaleService.getSales(shiftId: widget.shiftId);
  }

  void _refreshSales() {
    setState(() {
      _salesFuture = SaleService.getSales(shiftId: widget.shiftId);
    });
  }

  dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().isNotEmpty) return value;
    }
    return null;
  }

  String _formatTime(dynamic value) {
    if (value == null) return 'Hora no disponible';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatMoney(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ventas del Turno Activo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar ventas',
                  onPressed: _refreshSales,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _salesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Text('No se pudieron cargar las ventas del turno.'),
                      TextButton.icon(
                        onPressed: _refreshSales,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  );
                }

                final sales = snapshot.data ?? [];
                if (sales.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No hay ventas registradas en este turno.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final saleId = _firstValue(sale, [
                      'saleId',
                      'sale_id',
                      'id',
                    ]);
                    final createdAt = _firstValue(sale, [
                      'createdAt',
                      'created_at',
                    ]);
                    final paymentMethod = _firstValue(sale, [
                      'paymentMethod',
                      'payment_method',
                    ]);
                    final rawItems = sale['items'] ?? sale['products'];
                    final itemCount = rawItems is List ? rawItems.length : 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Venta #${saleId ?? 'N/D'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_formatTime(createdAt)} · ${paymentMethod ?? 'Pago N/D'} · $itemCount artículos',
                      ),
                      trailing: Text(
                        _formatMoney(sale['total']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
