import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const PagameApp());
}

class PagameApp extends StatelessWidget {
  const PagameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pagame',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22D3EE),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF041C36),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF16C7DB),
          contentTextStyle: TextStyle(
            color: Color(0xFF03233F),
            fontWeight: FontWeight.w700,
          ),
          actionTextColor: Color(0xFF03233F),
          elevation: 8,
        ),
        useMaterial3: true,
      ),
      home: const CategoriesScreen(),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedTab = 0;
  final List<_CategoryItem> _categories = [];
  final Map<String, List<_ServiceItem>> _servicesByCategoryId = {};

  void _showPlaceholderMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF03233F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }

  Future<void> _openCreateCategorySheet() async {
    final newCategory = await showModalBottomSheet<_CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateCategorySheet(),
    );

    if (!mounted) {
      return;
    }

    if (newCategory == null) {
      return;
    }

    setState(() {
      _categories.insert(0, newCategory);
      _servicesByCategoryId[newCategory.id] = [];
    });

    _showPlaceholderMessage('Categoría "${newCategory.name}" creada.');
  }

  void _openCategoryServices(_CategoryItem category) {
    final currentServices = _servicesByCategoryId[category.id] ?? [];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _CategoryServicesScreen(
          category: category,
          initialServices: currentServices,
          onServicesChanged: (updatedServices) {
            setState(() {
              _servicesByCategoryId[category.id] = updatedServices;
            });
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 0) {
      if (_categories.isEmpty) {
        return _CategoriesEmptyState(
          onCreateCategory: _openCreateCategorySheet,
        );
      }

      return _CategoriesListState(
        categories: _categories,
        servicesByCategoryId: _servicesByCategoryId,
        onOpenCategory: _openCategoryServices,
      );
    }

    if (_selectedTab == 1) {
      return const _SimpleTabState(
        icon: Icons.notifications_active_outlined,
        title: 'Vencimientos',
        subtitle: 'Aquí verás pagos próximos a vencer y vencidos.',
      );
    }

    return const _SimpleTabState(
      icon: Icons.settings_outlined,
      title: 'Ajustes',
      subtitle: 'Aquí configuraremos seguridad, hora de avisos y más.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _MainHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0 && _categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCreateCategorySheet,
              backgroundColor: const Color(0xFF16C7DB),
              foregroundColor: const Color(0xFF03233F),
              icon: const Icon(Icons.add),
              label: const Text('Nueva categoría'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (value) {
          setState(() {
            _selectedTab = value;
          });
        },
        backgroundColor: const Color(0xFF041C36),
        indicatorColor: const Color(0xFF16C7DB),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Vencimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _CategoriesEmptyState extends StatelessWidget {
  const _CategoriesEmptyState({required this.onCreateCategory});

  final VoidCallback onCreateCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF12B6CC), Color(0xFF1469A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x663EA8D4),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.folder_open, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 22),
          Text(
            'Aún no tienes categorías',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF10243E),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Empieza creando una categoría para agrupar tus servicios y registrar pagos mes a mes.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF4E6A86),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _InfoChip(icon: Icons.calendar_month_outlined, text: 'Mensuales'),
              _InfoChip(icon: Icons.receipt_long_outlined, text: 'Pago único'),
              _InfoChip(icon: Icons.task_alt_outlined, text: 'Pendientes'),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateCategory,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF16C7DB),
                foregroundColor: const Color(0xFF03233F),
                textStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear primera categoría'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesListState extends StatelessWidget {
  const _CategoriesListState({
    required this.categories,
    required this.servicesByCategoryId,
    required this.onOpenCategory,
  });

  final List<_CategoryItem> categories;
  final Map<String, List<_ServiceItem>> servicesByCategoryId;
  final ValueChanged<_CategoryItem> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemBuilder: (context, index) {
        final category = categories[index];
        final serviceCount = servicesByCategoryId[category.id]?.length ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD9E4EF)),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () => onOpenCategory(category),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: Colors.white),
              ),
              title: Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF10243E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                serviceCount == 0
                    ? 'Sin servicios aún'
                    : '$serviceCount servicio${serviceCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B748D),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7CC0E8),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: categories.length,
    );
  }
}

class _MainHeader extends StatelessWidget {
  const _MainHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Págame',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Gestiona tus pagos con orden',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8CB4D8),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF041C36),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF25507A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF9EC6E8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Hoy',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFD5E7F7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTabState extends StatelessWidget {
  const _SimpleTabState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF79A8D1)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF10243E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF4E6A86)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2A49),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF1F4A74)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7CC0E8)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFD5E7F7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  _ServiceItem({
    required this.name,
    required this.type,
    required this.billingCycle,
    Map<int, Set<int>>? monthsByYear,
    Map<String, List<_PaymentRecord>>? paymentsByPeriod,
  }) : monthsByYear = monthsByYear ?? <int, Set<int>>{},
       paymentsByPeriod = paymentsByPeriod ?? <String, List<_PaymentRecord>>{};

  final String name;
  final String type;
  final String billingCycle;
  final Map<int, Set<int>> monthsByYear;
  final Map<String, List<_PaymentRecord>> paymentsByPeriod;
}

class _PaymentRecord {
  const _PaymentRecord({
    required this.status,
    this.amount,
    required this.paymentDate,
    this.notes,
    this.attachments = const <String>[],
  });

  final String status;
  final double? amount;
  final DateTime paymentDate;
  final String? notes;
  final List<String> attachments;
}

class _CategoryServicesScreen extends StatefulWidget {
  const _CategoryServicesScreen({
    required this.category,
    required this.initialServices,
    required this.onServicesChanged,
  });

  final _CategoryItem category;
  final List<_ServiceItem> initialServices;
  final ValueChanged<List<_ServiceItem>> onServicesChanged;

  @override
  State<_CategoryServicesScreen> createState() =>
      _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<_CategoryServicesScreen> {
  late final List<_ServiceItem> _services = List<_ServiceItem>.from(
    widget.initialServices,
  );

  Future<void> _openServiceTimeline(_ServiceItem service) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _ServiceTimelineScreen(service: service),
      ),
    );

    if (mounted) {
      setState(() {});
      widget.onServicesChanged(_services);
    }
  }

  Future<void> _openCreateServiceSheet() async {
    final newService = await showModalBottomSheet<_ServiceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateServiceSheet(),
    );

    if (!mounted) {
      return;
    }

    if (newService == null) {
      return;
    }

    setState(() {
      _services.insert(0, newService);
    });
    widget.onServicesChanged(_services);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF03233F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Servicio "${newService.name}" creado.')),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF041C36),
        foregroundColor: Colors.white,
        title: Text(widget.category.name),
      ),
      floatingActionButton: _services.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCreateServiceSheet,
              backgroundColor: const Color(0xFF16C7DB),
              foregroundColor: const Color(0xFF03233F),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo servicio'),
            )
          : null,
      body: Container(
        color: Colors.white,
        child: _services.isEmpty
            ? _ServicesEmptyState(onCreateService: _openCreateServiceSheet)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E4EF)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => _openServiceTimeline(service),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Color(0xFF7CC0E8),
                          ),
                        ),
                        title: Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF10243E),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: Text(
                          '${service.type} · ${service.billingCycle}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5B748D)),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF7CC0E8),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: _services.length,
              ),
      ),
    );
  }
}

class _ServiceTimelineScreen extends StatefulWidget {
  const _ServiceTimelineScreen({required this.service});

  final _ServiceItem service;

  @override
  State<_ServiceTimelineScreen> createState() => _ServiceTimelineScreenState();
}

class _ServiceTimelineScreenState extends State<_ServiceTimelineScreen> {
  List<int> get _years {
    final values = widget.service.monthsByYear.keys.toList()
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFF03233F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _createYear() async {
    final selectedYear = await _showYearPicker(context);
    if (!mounted || selectedYear == null) {
      return;
    }

    if (widget.service.monthsByYear.containsKey(selectedYear)) {
      _showInfoMessage('El año $selectedYear ya existe en este servicio.');
      return;
    }

    setState(() {
      widget.service.monthsByYear[selectedYear] = <int>{};
    });
    _showInfoMessage('Año $selectedYear creado.');
  }

  Future<void> _openYearMonths(int year) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            _YearMonthsScreen(service: widget.service, year: year),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF041C36),
        foregroundColor: Colors.white,
        title: Text(widget.service.name),
      ),
      floatingActionButton: years.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createYear,
              backgroundColor: const Color(0xFF16C7DB),
              foregroundColor: const Color(0xFF03233F),
              icon: const Icon(Icons.add),
              label: const Text('Crear año'),
            )
          : null,
      body: Container(
        color: Colors.white,
        child: years.isEmpty
            ? _YearsEmptyState(onCreateYear: _createYear)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                itemCount: years.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final year = years[index];
                  final monthCount =
                      widget.service.monthsByYear[year]?.length ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E4EF)),
                    ),
                    child: Material(
                      color: Colors.transparent,
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
                            color: const Color(0xFFE8F2FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF7CC0E8),
                          ),
                        ),
                        title: Text(
                          '$year',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF10243E),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: Text(
                          monthCount == 0
                              ? 'Sin meses aún'
                              : '$monthCount mes${monthCount == 1 ? '' : 'es'}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5B748D)),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF7CC0E8),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                colors: [Color(0xFF12B6CC), Color(0xFF1469A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x663EA8D4),
                  blurRadius: 26,
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
            'Aún no tienes años',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF10243E),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Crea un año para organizar los meses de pago de este servicio.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF4E6A86),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateYear,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF16C7DB),
                foregroundColor: const Color(0xFF03233F),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear primer año'),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearMonthsScreen extends StatefulWidget {
  const _YearMonthsScreen({required this.service, required this.year});

  final _ServiceItem service;
  final int year;

  @override
  State<_YearMonthsScreen> createState() => _YearMonthsScreenState();
}

class _YearMonthsScreenState extends State<_YearMonthsScreen> {
  List<int> get _months {
    final values =
        (widget.service.monthsByYear[widget.year] ?? <int>{}).toList()
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFF03233F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _createMonth() async {
    final selectedMonth = await _showMonthPicker(context);
    if (!mounted || selectedMonth == null) {
      return;
    }

    final monthSet = widget.service.monthsByYear[widget.year] ?? <int>{};
    if (monthSet.contains(selectedMonth)) {
      _showInfoMessage('El mes ${_monthName(selectedMonth)} ya existe.');
      return;
    }

    setState(() {
      monthSet.add(selectedMonth);
      widget.service.monthsByYear[widget.year] = monthSet;
    });
    _showInfoMessage('Mes ${_monthName(selectedMonth)} creado.');
  }

  Future<void> _openMonthPayments(int month) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _MonthPaymentsScreen(
          service: widget.service,
          year: widget.year,
          month: month,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF041C36),
        foregroundColor: Colors.white,
        title: Text('${widget.year} - Meses'),
      ),
      floatingActionButton: months.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createMonth,
              backgroundColor: const Color(0xFF16C7DB),
              foregroundColor: const Color(0xFF03233F),
              icon: const Icon(Icons.add),
              label: const Text('Crear mes'),
            )
          : null,
      body: Container(
        color: Colors.white,
        child: months.isEmpty
            ? _MonthsEmptyState(onCreateMonth: _createMonth)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                itemCount: months.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final month = months[index];
                  final periodKey = '${widget.year}-$month';
                  final paymentCount =
                      widget.service.paymentsByPeriod[periodKey]?.length ?? 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E4EF)),
                    ),
                    child: Material(
                      color: Colors.transparent,
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
                            color: const Color(0xFFE8F2FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_note_outlined,
                            color: Color(0xFF7CC0E8),
                          ),
                        ),
                        title: Text(
                          _monthName(month),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF10243E),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: Text(
                          paymentCount == 0
                              ? 'Sin pagos registrados'
                              : '$paymentCount pago${paymentCount == 1 ? '' : 's'} registrados',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5B748D)),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF7CC0E8),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MonthPaymentsScreen extends StatefulWidget {
  const _MonthPaymentsScreen({
    required this.service,
    required this.year,
    required this.month,
  });

  final _ServiceItem service;
  final int year;
  final int month;

  @override
  State<_MonthPaymentsScreen> createState() => _MonthPaymentsScreenState();
}

class _MonthPaymentsScreenState extends State<_MonthPaymentsScreen> {
  String get _periodKey => '${widget.year}-${widget.month}';

  List<_PaymentRecord> get _payments {
    final values =
        widget.service.paymentsByPeriod[_periodKey] ?? <_PaymentRecord>[];
    values.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return values;
  }

  Future<void> _createPayment() async {
    final payment = await showModalBottomSheet<_PaymentRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePaymentSheet(),
    );

    if (!mounted || payment == null) {
      return;
    }

    setState(() {
      final list =
          widget.service.paymentsByPeriod[_periodKey] ?? <_PaymentRecord>[];
      list.add(payment);
      widget.service.paymentsByPeriod[_periodKey] = list;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Pago registrado correctamente.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final payments = _payments;
    final monthName = _monthName(widget.month);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF041C36),
        foregroundColor: Colors.white,
        title: Text('$monthName ${widget.year}'),
      ),
      floatingActionButton: payments.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createPayment,
              backgroundColor: const Color(0xFF16C7DB),
              foregroundColor: const Color(0xFF03233F),
              icon: const Icon(Icons.add),
              label: const Text('Agregar pago'),
            )
          : null,
      body: Container(
        color: Colors.white,
        child: payments.isEmpty
            ? _MonthPaymentsEmptyState(onCreatePayment: _createPayment)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                itemCount: payments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final hasNotes = (payment.notes ?? '').isNotEmpty;
                  final dateAndNotes = hasNotes
                      ? '${_formatDate(payment.paymentDate)} · ${payment.notes}'
                      : _formatDate(payment.paymentDate);
                  final attachmentSummary = payment.attachments.isEmpty
                      ? ''
                      : '\nAdjuntos: ${payment.attachments.length}';
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E4EF)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: Color(0xFF7CC0E8),
                          ),
                        ),
                        title: Text(
                          payment.amount == null
                              ? payment.status
                              : 'S/ ${payment.amount!.toStringAsFixed(2)} · ${payment.status}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF10243E),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: Text(
                          '$dateAndNotes$attachmentSummary',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5B748D)),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MonthPaymentsEmptyState extends StatelessWidget {
  const _MonthPaymentsEmptyState({required this.onCreatePayment});

  final VoidCallback onCreatePayment;

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
                colors: [Color(0xFF12B6CC), Color(0xFF1469A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x663EA8D4),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Aún no tienes pagos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF10243E),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Registra el primer pago de este mes para empezar el historial.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF4E6A86),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreatePayment,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF16C7DB),
                foregroundColor: const Color(0xFF03233F),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear primer pago'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePaymentSheet extends StatefulWidget {
  const _CreatePaymentSheet();

  @override
  State<_CreatePaymentSheet> createState() => _CreatePaymentSheetState();
}

class _CreatePaymentSheetState extends State<_CreatePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _attachments = <String>[];

  String _status = 'Pendiente';
  DateTime _paymentDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );

    if (selected != null) {
      setState(() {
        _paymentDate = selected;
      });
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'pdf',
        'doc',
        'docx',
      ],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final fileNames = result.files
        .map((file) => file.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (fileNames.isEmpty) {
      return;
    }

    setState(() {
      for (final fileName in fileNames) {
        if (!_attachments.contains(fileName)) {
          _attachments.add(fileName);
        }
      }
    });
  }

  void _removeAttachment(String fileName) {
    setState(() {
      _attachments.remove(fileName);
    });
  }

  String _compactFileName(String value) {
    if (value.length <= 24) {
      return value;
    }
    return '${value.substring(0, 21)}...';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty ? null : double.parse(amountText);

    Navigator.of(context).pop(
      _PaymentRecord(
        status: _status,
        amount: amount,
        paymentDate: _paymentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        attachments: List<String>.from(_attachments),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5275),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nuevo pago',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF10243E)),
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(value: 'Pagado', child: Text('Pagado')),
                      DropdownMenuItem(
                        value: 'Vencido',
                        child: Text('Vencido'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Color(0xFF10243E)),
                    decoration: InputDecoration(
                      labelText: 'Monto (opcional)',
                      labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }

                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Ingresa un monto válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de pago',
                        labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E4EF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E4EF),
                          ),
                        ),
                      ),
                      child: Text(
                        _formatDate(_paymentDate),
                        style: const TextStyle(color: Color(0xFF10243E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    style: const TextStyle(color: Color(0xFF10243E)),
                    decoration: InputDecoration(
                      labelText: 'Notas (opcional)',
                      labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickAttachments,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0E3A60),
                        side: const BorderSide(color: Color(0xFFD9E4EF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text('Adjuntar imagen o archivo'),
                    ),
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments
                          .map(
                            (fileName) => InputChip(
                              label: Text(_compactFileName(fileName)),
                              onDeleted: () => _removeAttachment(fileName),
                              backgroundColor: const Color(0xFFE8F2FB),
                              deleteIconColor: const Color(0xFF33526D),
                              labelStyle: const TextStyle(
                                color: Color(0xFF10243E),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF16C7DB),
                        foregroundColor: const Color(0xFF03233F),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar pago'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
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
                colors: [Color(0xFF12B6CC), Color(0xFF1469A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x663EA8D4),
                  blurRadius: 26,
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
            'Aún no tienes meses',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF10243E),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Agrega meses para registrar los pagos de este año.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF4E6A86),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateMonth,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF16C7DB),
                foregroundColor: const Color(0xFF03233F),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear primer mes'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<int?> _showYearPicker(BuildContext context) async {
  const years = <int>[2025, 2026, 2027, 2028];
  final current = DateTime.now().year.clamp(2025, 2028);
  int selectedYear = current;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final controller = FixedExtentScrollController(
        initialItem: years.indexOf(selectedYear),
      );

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5275),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecciona el año',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListWheelScrollView.useDelegate(
                      controller: controller,
                      itemExtent: 44,
                      perspective: 0.003,
                      diameterRatio: 1.3,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          selectedYear = years[index];
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: years.length,
                        builder: (context, index) {
                          final year = years[index];
                          final selected = year == selectedYear;
                          return Center(
                            child: Text(
                              year.toString(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: selected
                                        ? const Color(0xFF16C7DB)
                                        : const Color(0xFF8CB4D8),
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(selectedYear),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16C7DB),
                        foregroundColor: const Color(0xFF03233F),
                      ),
                      child: const Text('Agregar año'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<int?> _showMonthPicker(BuildContext context) async {
  const months = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  final current = DateTime.now().month;
  int selectedMonth = current;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final controller = FixedExtentScrollController(
        initialItem: months.indexOf(selectedMonth),
      );

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5275),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecciona el mes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListWheelScrollView.useDelegate(
                      controller: controller,
                      itemExtent: 44,
                      perspective: 0.003,
                      diameterRatio: 1.3,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          selectedMonth = months[index];
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: months.length,
                        builder: (context, index) {
                          final month = months[index];
                          final selected = month == selectedMonth;
                          return Center(
                            child: Text(
                              _monthName(month),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: selected
                                        ? const Color(0xFF16C7DB)
                                        : const Color(0xFF8CB4D8),
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(selectedMonth),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16C7DB),
                        foregroundColor: const Color(0xFF03233F),
                      ),
                      child: const Text('Agregar mes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _monthName(int month) {
  const names = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return names[month - 1];
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState({required this.onCreateService});

  final VoidCallback onCreateService;

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
                colors: [Color(0xFF12B6CC), Color(0xFF1469A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x663EA8D4),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.subscriptions_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Aún no tienes servicios',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF10243E),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Agrega tu primer servicio en esta categoría, por ejemplo Prime Video.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF4E6A86),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateService,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF16C7DB),
                foregroundColor: const Color(0xFF03233F),
                textStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear primer servicio'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateServiceSheet extends StatefulWidget {
  const _CreateServiceSheet();

  @override
  State<_CreateServiceSheet> createState() => _CreateServiceSheetState();
}

class _CreateServiceSheetState extends State<_CreateServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _type = 'Mensual';
  String _billingCycle = 'Fin de mes';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final billingCycle = _type == 'Único' ? 'Sin vencimiento' : _billingCycle;

    Navigator.of(context).pop(
      _ServiceItem(
        name: _nameController.text.trim(),
        type: _type,
        billingCycle: billingCycle,
        monthsByYear: <int, Set<int>>{},
        paymentsByPeriod: <String, List<_PaymentRecord>>{},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5275),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nuevo servicio',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ejemplo: Prime Video',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5B748D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Color(0xFF10243E)),
                    decoration: InputDecoration(
                      labelText: 'Nombre del servicio',
                      labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del servicio es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF10243E)),
                    decoration: InputDecoration(
                      labelText: 'Tipo de servicio',
                      labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Mensual',
                        child: Text('Mensual'),
                      ),
                      DropdownMenuItem(value: 'Único', child: Text('Único')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _type = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_type == 'Mensual')
                    DropdownButtonFormField<String>(
                      initialValue: _billingCycle,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF10243E)),
                      decoration: InputDecoration(
                        labelText: 'Frecuencia de cobro',
                        labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E4EF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E4EF),
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Quincena (día 15)',
                          child: Text('Quincena (día 15)'),
                        ),
                        DropdownMenuItem(
                          value: 'Fin de mes',
                          child: Text('Fin de mes'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _billingCycle = value;
                        });
                      },
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD9E4EF)),
                      ),
                      child: Text(
                        'Servicio único: sin vencimiento mensual',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5B748D),
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF16C7DB),
                        foregroundColor: const Color(0xFF03233F),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar servicio'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet();

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  IconData _selectedIcon = Icons.category_outlined;
  Color _selectedColor = const Color(0xFF0EA5E9);

  final List<IconData> _icons = const [
    Icons.category_outlined,
    Icons.play_circle_outline,
    Icons.electric_bolt_outlined,
    Icons.home_outlined,
    Icons.school_outlined,
    Icons.medical_services_outlined,
  ];

  final List<Color> _colors = const [
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFA855F7),
    Color(0xFF14B8A6),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _CategoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5275),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nueva categoría',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea una categoría para organizar tus servicios.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5B748D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Color(0xFF10243E)),
                    decoration: InputDecoration(
                      labelText: 'Nombre de la categoría',
                      labelStyle: const TextStyle(color: Color(0xFF5B748D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9E4EF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Icono',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _icons.map((icon) {
                      final selected = _selectedIcon == icon;
                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = icon),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF16C7DB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF16C7DB)
                                  : const Color(0xFFD9E4EF),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: selected
                                ? const Color(0xFF03233F)
                                : const Color(0xFF5B748D),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Color',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF10243E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colors.map((color) {
                      final selected = _selectedColor == color;
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF16C7DB),
                        foregroundColor: const Color(0xFF03233F),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar categoría'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
