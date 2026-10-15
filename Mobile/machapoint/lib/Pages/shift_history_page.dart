import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/sale.dart';
import '../services/user_service.dart';

class ShiftHistoryPage extends StatefulWidget {
  const ShiftHistoryPage({super.key});

  @override
  State<ShiftHistoryPage> createState() => _ShiftHistoryPageState();
}

class _ShiftHistoryPageState extends State<ShiftHistoryPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  int? _selectedPeriodDays = 1;
  late Future<List<Map<String, dynamic>>> _salesFuture;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today;
    _endDate = today;
    _salesFuture = _loadSales(today, today);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<List<Map<String, dynamic>>> _loadSales(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final responseSales = await SaleService.getSalesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    final localStart = DateTime(startDate.year, startDate.month, startDate.day);
    final localEndExclusive = DateTime(endDate.year, endDate.month, endDate.day + 1);
    final sales = responseSales.where((sale) {
      final rawDate = _value(sale, [
        'createdAt',
        'created_at',
        'saleDate',
        'sale_date',
        'date',
      ]);
      final parsedDate = DateTime.tryParse(rawDate?.toString() ?? '');
      if (parsedDate == null) return false;
      final localDate = parsedDate.toLocal();
      return !localDate.isBefore(localStart) && localDate.isBefore(localEndExclusive);
    }).toList();
    final users = await UserService.getUsers();
    final cashierNames = {
      for (final user in users)
        if (user.userId.isNotEmpty)
          user.userId.toLowerCase(): _displayUserName(user),
    };
    for (var index = 0; index < sales.length; index++) {
      final sale = sales[index];
      final existingName = _value(sale, ['cashierName', 'cashier_name']);
      final cashierId = _value(sale, ['cashierId', 'cashier_id']);
      final name =
          existingName ??
          cashierNames[cashierId?.toString().toLowerCase()] ??
          _value(sale, ['cashierUsername', 'cashier_username']) ??
          cashierId;
      sales[index] = {...sale, 'cashierDisplayName': name};
    }
    sales.sort((a, b) {
      final first = DateTime.tryParse(
        _value(a, [
              'createdAt',
              'created_at',
              'saleDate',
              'sale_date',
              'date',
            ])?.toString() ??
            '',
      );
      final second = DateTime.tryParse(
        _value(b, [
              'createdAt',
              'created_at',
              'saleDate',
              'sale_date',
              'date',
            ])?.toString() ??
            '',
      );
      if (first == null) return second == null ? 0 : 1;
      if (second == null) return -1;
      return second.compareTo(first);
    });
    return sales;
  }

  static dynamic _value(Map<String, dynamic> source, Iterable<String> keys) {
    final normalized = {
      for (final entry in source.entries)
        entry.key.toLowerCase().replaceAll(RegExp(r'[_\s-]'), ''): entry.value,
    };
    for (final key in keys) {
      final value =
          normalized[key.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '')];
      if (value != null && value.toString().isNotEmpty) return value;
    }
    return null;
  }

  static String _displayUserName(UserRecord user) {
    final firstName = user.firstname.trim();
    if (firstName.isNotEmpty) return firstName;
    return user.username;
  }

  void _querySales() {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha inicial no puede ser posterior a la fecha final.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _salesFuture = _loadSales(_startDate, _endDate);
    });
  }

  Future<void> _refreshSales() async {
    final future = _loadSales(_startDate, _endDate);
    setState(() {
      _salesFuture = future;
    });
    try {
      await future;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el historial: $error')),
      );
    }
  }

  void _selectPeriod(int days) {
    final today = _dateOnly(DateTime.now());
    setState(() {
      _selectedPeriodDays = days;
      _endDate = today;
      _startDate = days == 1 ? today : today.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _selectedPeriodDays = null;
      if (isStart) {
        _startDate = _dateOnly(selected);
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = _dateOnly(selected);
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatDateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'N/D';
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour < 12 ? 'a. m.' : 'p. m.';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year.toString().substring(2)}, '
        '$hour:${local.minute.toString().padLeft(2, '0')} $period';
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return amount == null ? 'N/D' : '\$${amount.toStringAsFixed(2)}';
  }

  double _totalSales(List<Map<String, dynamic>> sales) {
    return sales.fold<double>(0, (sum, sale) {
      final total = _value(sale, ['total', 'saleTotal', 'sale_total']);
      final amount = total is num
          ? total.toDouble()
          : double.tryParse(total?.toString() ?? '');
      return sum + (amount ?? 0);
    });
  }

  Widget _dateSelector(String label, DateTime value, {required bool isStart}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => _pickDate(isStart: isStart),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFE7C78E)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF2B04E);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _salesFuture,
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _refreshSales,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Historial de ventas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                width: 190,
                height: 2,
                color: orange,
                margin: const EdgeInsets.only(top: 6, bottom: 16),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _periodButton('1 Día', 1),
                  _periodButton('1 Semana', 7),
                  _periodButton('1 Mes', 30),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _dateSelector('Fecha inicio', _startDate, isStart: true),
                  const SizedBox(width: 10),
                  _dateSelector('Fecha fin', _endDate, isStart: false),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : _querySales,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Consultar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                _errorState(snapshot.error)
              else ...[
                _summary(sales),
                const SizedBox(height: 18),
                if (sales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No hay ventas en el periodo seleccionado.'),
                    ),
                  )
                else
                  _salesTable(sales),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _periodButton(String label, int days) {
    final selected = _selectedPeriodDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _selectPeriod(days),
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: const Color(0xFFF7F5F0),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('No se pudo cargar el historial: $error'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _querySales,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _summary(List<Map<String, dynamic>> sales) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          _summaryValue('Ventas', '${sales.length}'),
          const SizedBox(width: 20),
          _summaryValue('Total vendido', _money(_totalSales(sales))),
        ],
      ),
    );
  }

  Widget _summaryValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _salesTable(List<Map<String, dynamic>> sales) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F5F0)),
        columns: const [
          DataColumn(label: Text('VENTA')),
          DataColumn(label: Text('FECHA Y HORA')),
          DataColumn(label: Text('TURNO')),
          DataColumn(label: Text('CAJERO')),
          DataColumn(label: Text('TOTAL')),
        ],
        rows: sales.map((sale) {
          final createdAt = _value(sale, [
            'createdAt',
            'created_at',
            'saleDate',
            'sale_date',
            'date',
          ]);
          return DataRow(
            cells: [
              DataCell(
                Text(
                  '#${_value(sale, ['saleId', 'sale_id', 'id']) ?? 'N/D'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(_formatDateTime(createdAt))),
              DataCell(
                Text(
                  '#${_value(sale, ['shiftId', 'shift_id', 'shiftid']) ?? 'N/D'}',
                ),
              ),
              DataCell(
                Text('${_value(sale, ['cashierDisplayName']) ?? 'N/D'}'),
              ),
              DataCell(
                Text(
                  _money(_value(sale, ['total', 'saleTotal', 'sale_total'])),
                  style: const TextStyle(
                    color: Color(0xFFE08A00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
