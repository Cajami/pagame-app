import 'package:flutter/material.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/screens/services/month_payments_screen.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/utils/date_utils.dart';
import 'package:pagame/widgets/common/app_background.dart';
import 'package:pagame/widgets/pickers/month_picker_bottom_sheet.dart';

class YearMonthsScreen extends StatefulWidget {
  const YearMonthsScreen({
    super.key,
    required this.service,
    required this.year,
  });

  final ServiceItem service;
  final int year;

  @override
  State<YearMonthsScreen> createState() => _YearMonthsScreenState();
}

class _YearMonthsScreenState extends State<YearMonthsScreen> {
  List<int> _months = [];
  Map<int, int> _paymentCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthsData();
  }

  Future<void> _loadMonthsData() async {
    setState(() => _isLoading = true);
    try {
      final yearId = '${widget.service.id}_${widget.year}';
      final dbMonths = await DatabaseHelper.instance.getMonthsForYear(yearId);
      final Map<int, int> counts = {};
      for (final month in dbMonths) {
        final monthId = '${yearId}_$month';
        counts[month] = await DatabaseHelper.instance.getPaymentCountForMonth(monthId);
      }
      if (mounted) {
        setState(() {
          _months = dbMonths..sort((a, b) => b.compareTo(a));
          _paymentCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading months data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.ink, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _createMonth() async {
    final selectedMonth = await showMonthPicker(context, existingMonths: _months);
    if (!mounted || selectedMonth == null) {
      return;
    }

    if (_months.contains(selectedMonth)) {
      _showInfoMessage('El mes ${monthName(selectedMonth)} ya existe.');
      return;
    }

    final yearId = '${widget.service.id}_${widget.year}';
    final monthId = '${yearId}_$selectedMonth';
    
    try {
      debugPrint('Creating month: yearId=$yearId, monthId=$monthId, month=$selectedMonth');
      await DatabaseHelper.instance.insertYear(yearId, widget.service.id, widget.year);
      await DatabaseHelper.instance.insertMonth(monthId, yearId, selectedMonth);

      await _loadMonthsData();
      _showInfoMessage('Mes ${monthName(selectedMonth)} creado.');
    } catch (e, stackTrace) {
      debugPrint('Error creating month: $e');
      debugPrint(stackTrace.toString());
      _showInfoMessage('Error al crear mes: $e');
    }
  }

  Future<void> _openMonthPayments(int month) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MonthPaymentsScreen(
          service: widget.service,
          year: widget.year,
          month: month,
        ),
      ),
    );

    if (mounted) {
      _loadMonthsData();
    }
  }

  Future<void> _deleteMonthAction(int month) async {
    final monthId = '${widget.service.id}_${widget.year}_$month';
    final hasPayments = await DatabaseHelper.instance.hasPaymentsForMonth(monthId);
    if (hasPayments) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: Text('No se puede eliminar', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          content: Text(
            'Este mes tiene pagos registrados. Elimina primero todos sus pagos para poder borrarlo.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text('Eliminar mes', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar el mes de ${monthName(month)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteMonth(monthId);
      await _loadMonthsData();
      _showInfoMessage('Mes de ${monthName(month)} eliminado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const HeaderBackground(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.service.name,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
            ),
            Text(' - ${widget.year}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Volver al Inicio',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      floatingActionButton: _months.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createMonth,
              icon: const Icon(Icons.add),
              label: const Text('Crear mes'),
            )
          : null,
      body: Stack(
        children: [
          const AppBackground(),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _months.isEmpty
                  ? _MonthsEmptyState(onCreateMonth: _createMonth)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                      itemCount: _months.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final month = _months[index];
                        final paymentCount = _paymentCounts[month] ?? 0;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: ListTile(
                              onTap: () => _openMonthPayments(month),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0x1A18C1B5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.event_note_outlined,
                                  color: AppColors.accent,
                                ),
                              ),
                              title: Text(
                                monthName(month),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              subtitle: Text(
                                paymentCount == 0
                                    ? 'Sin pagos registrados'
                                    : '$paymentCount pago${paymentCount == 1 ? '' : 's'} registrados',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.inkMuted),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
                                color: AppColors.card,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteMonthAction(month);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

class _MonthsEmptyState extends StatelessWidget {
  const _MonthsEmptyState({required this.onCreateMonth});

  final VoidCallback onCreateMonth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF18C1B5), Color(0xFF3F88C5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2618C1B5),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Sin meses registrados',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Selecciona los meses que quieres seguir.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.inkSoft,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateMonth,
              icon: const Icon(Icons.add),
              label: const Text('Crear mes'),
            ),
          ),
        ],
      ),
    );
  }
}
