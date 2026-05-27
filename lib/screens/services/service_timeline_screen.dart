import 'package:flutter/material.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/screens/services/year_months_screen.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/widgets/common/app_background.dart';
import 'package:pagame/widgets/pickers/year_picker_bottom_sheet.dart';


class ServiceTimelineScreen extends StatefulWidget {
  const ServiceTimelineScreen({super.key, required this.service});

  final ServiceItem service;

  @override
  State<ServiceTimelineScreen> createState() => _ServiceTimelineScreenState();
}

class _ServiceTimelineScreenState extends State<ServiceTimelineScreen> {
  late ServiceItem _currentService;

  @override
  void initState() {
    super.initState();
    _currentService = widget.service;
  }

  List<int> get _years {
    final values = _currentService.monthsByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return values;
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

  Future<void> _createYear() async {
    final selectedYear = await showYearPicker(context, existingYears: _currentService.monthsByYear.keys.toList());
    if (!mounted || selectedYear == null) {
      return;
    }

    if (_currentService.monthsByYear.containsKey(selectedYear)) {
      _showInfoMessage('El año $selectedYear ya existe en este servicio.');
      return;
    }

    final yearId = '${_currentService.id}_$selectedYear';
    await DatabaseHelper.instance.insertYear(yearId, _currentService.id, selectedYear);

    setState(() {
      _currentService.monthsByYear[selectedYear] = <int>{};
    });
    _showInfoMessage('Año $selectedYear creado.');
  }

  Future<void> _openYearMonths(int year) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            YearMonthsScreen(service: _currentService, year: year),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteYearAction(int year) async {
    final months = _currentService.monthsByYear[year] ?? <int>{};
    if (months.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: Text('No se puede eliminar', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          content: Text(
            'Este año tiene meses registrados. Elimina primero todos sus meses para poder borrarlo.',
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text('Eliminar año', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar el año $year?'),
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
      final yearId = '${_currentService.id}_$year';
      await DatabaseHelper.instance.deleteYear(yearId);
      setState(() {
        _currentService.monthsByYear.remove(year);
      });
      _showInfoMessage('Año $year eliminado.');
    }
  }



  @override
  Widget build(BuildContext context) {
    final years = _years;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const HeaderBackground(),
        title: Text(_currentService.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Volver al Inicio',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      floatingActionButton: years.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createYear,
              icon: const Icon(Icons.add),
              label: const Text('Crear año'),
            )
          : null,
      body: Stack(
        children: [
          const AppBackground(),
          years.isEmpty
              ? _YearsEmptyState(onCreateYear: _createYear)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  itemCount: years.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final monthCount =
                        _currentService.monthsByYear[year]?.length ?? 0;

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
                          onTap: () => _openYearMonths(year),
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
                              Icons.calendar_today_outlined,
                              color: AppColors.accent,
                            ),
                          ),
                          title: Text(
                            '$year',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          subtitle: Text(
                            monthCount == 0
                                ? 'Sin meses registrados'
                                : '$monthCount mes${monthCount == 1 ? '' : 'es'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
                            color: AppColors.card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteYearAction(year);
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

class _YearsEmptyState extends StatelessWidget {
  const _YearsEmptyState({required this.onCreateYear});

  final VoidCallback onCreateYear;

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
              Icons.date_range_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Sin años registrados',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Crea un año para ordenar los meses y pagos.',
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
              onPressed: onCreateYear,
              icon: const Icon(Icons.add),
              label: const Text('Crear año'),
            ),
          ),
        ],
      ),
    );
  }
}
