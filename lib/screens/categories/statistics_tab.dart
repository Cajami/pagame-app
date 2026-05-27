import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pagame/models/category_item.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/utils/date_utils.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  bool _isLoading = true;
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  String _selectedCurrency = 'PEN';
  int _activeSubTab = 0; // 0: Servicios, 1: Categorías

  // Curated premium high-contrast colors for category donut chart
  final List<Color> _donutColors = [
    const Color(0xFF18C1B5), // Brand teal
    const Color(0xFF3F88C5), // Beautiful blue
    const Color(0xFFF15BB5), // Vibrant pink
    const Color(0xFFF7B731), // Warm amber
    const Color(0xFF8338EC), // Purple
    const Color(0xFFFF006E), // Vibrant magenta
    const Color(0xFF38B000), // Vibrant green
  ];

  // KPI Metrics
  double _totalMonthExpenses = 0.0;
  double _averageMonthlyExpenses = 0.0;

  // Donut Chart Data
  List<Map<String, dynamic>> _categoryExpenses = [];
  int _touchedPieIndex = -1;

  // Bar Chart Data (History of selected service)
  List<CategoryItem> _allCategories = [];
  CategoryItem? _selectedCategory;
  List<ServiceItem> _allServices = [];
  List<ServiceItem> _filteredServices = [];
  ServiceItem? _selectedService;
  List<Map<String, dynamic>> _serviceHistory = [];

  // Year filter for service consumption history
  int? _selectedHistoryYear;
  List<int> _availableHistoryYears = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics(firstLoad: true);
  }

  Future<void> _loadStatistics({bool firstLoad = false}) async {
    if (firstLoad) {
      setState(() => _isLoading = true);
    }

    final db = DatabaseHelper.instance;

    // 1. Get expenses by category for current month, filtered by currency
    final categoryExpenses = await db.getMonthlyCategoryExpenses(
      year: _currentYear,
      month: _currentMonth,
      moneda: _selectedCurrency,
    );

    // Calculate total month expenses
    double totalMonth = 0;
    for (final exp in categoryExpenses) {
      totalMonth += (exp['total'] as num?)?.toDouble() ?? 0.0;
    }

    // 2. Calculate historical average monthly expenses, filtered by currency
    final allPayments = await db.getAllPaymentsRaw();
    double totalAllTime = 0.0;
    final Set<String> activePeriods = {};

    for (final pay in allPayments) {
      final moneda = pay['moneda'] as String? ?? 'PEN';
      if (moneda != _selectedCurrency) continue;

      final amount = pay['monto'] as num?;
      if (amount != null) {
        totalAllTime += amount.toDouble();
        
        // Extract period from mes_id (format: serviceId_year_month)
        final mesId = pay['mes_id'] as String?;
        if (mesId != null) {
          final parts = mesId.split('_');
          if (parts.length >= 3) {
            final period = '${parts[parts.length - 2]}_${parts[parts.length - 1]}';
            activePeriods.add(period);
          }
        }
      }
    }

    final averageExpenses = activePeriods.isEmpty 
        ? totalAllTime 
        : totalAllTime / activePeriods.length;

    // 3. Load all categories and services for the history selector
    final categories = await db.getCategories();
    final services = await db.getAllServices();
    
    // Preserve category selection matching by ID
    CategoryItem? selectedCat;
    if (_selectedCategory != null) {
      try {
        selectedCat = categories.firstWhere((c) => c.id == _selectedCategory!.id);
      } catch (_) {}
    }
    // Prioritize first category that has at least one service so dropdown doesn't look empty
    selectedCat ??= categories.isNotEmpty
        ? categories.firstWhere(
            (c) => services.any((s) => s.categoryId == c.id),
            orElse: () => categories.first,
          )
        : null;

    List<ServiceItem> filtered = [];
    if (selectedCat != null) {
      filtered = services.where((s) => s.categoryId == selectedCat!.id).toList();
    }

    // Preserve service selection matching by ID
    ServiceItem? selectedServ;
    if (_selectedService != null) {
      try {
        selectedServ = filtered.firstWhere((s) => s.id == _selectedService!.id);
      } catch (_) {}
    }
    selectedServ ??= filtered.isNotEmpty ? filtered.first : null;

    List<Map<String, dynamic>> history = [];
    if (selectedServ != null) {
      history = await db.getServicePaymentsHistory(selectedServ.id, _selectedCurrency);
    }

    // Extract unique available years from the payment history
    final Set<int> yearsSet = {};
    for (final h in history) {
      yearsSet.add(h['anio'] as int);
    }
    final yearsList = yearsSet.toList()..sort((a, b) => b.compareTo(a));

    int? selectedHistoryYear = _selectedHistoryYear;
    if (yearsList.isNotEmpty) {
      if (selectedHistoryYear == null || !yearsList.contains(selectedHistoryYear)) {
        selectedHistoryYear = yearsList.first;
      }
    } else {
      selectedHistoryYear = DateTime.now().year;
    }

    if (mounted) {
      setState(() {
        _categoryExpenses = categoryExpenses;
        _totalMonthExpenses = totalMonth;
        _averageMonthlyExpenses = averageExpenses;
        _allCategories = categories;
        _selectedCategory = selectedCat;
        _allServices = services;
        _filteredServices = filtered;
        _selectedService = selectedServ;
        _serviceHistory = history;
        _availableHistoryYears = yearsList;
        _selectedHistoryYear = selectedHistoryYear;
        _isLoading = false;
      });
    }
  }

  Future<void> _onCategoryChanged(CategoryItem? category) async {
    if (category == null) return;
    
    final filtered = _allServices.where((s) => s.categoryId == category.id).toList();
    ServiceItem? selectedServ = filtered.isNotEmpty ? filtered.first : null;
    List<Map<String, dynamic>> history = [];
    
    if (selectedServ != null) {
      history = await DatabaseHelper.instance.getServicePaymentsHistory(selectedServ.id, _selectedCurrency);
    }

    final Set<int> yearsSet = {};
    for (final h in history) {
      yearsSet.add(h['anio'] as int);
    }
    final yearsList = yearsSet.toList()..sort((a, b) => b.compareTo(a));

    int? selectedHistoryYear = yearsList.isNotEmpty ? yearsList.first : DateTime.now().year;
    
    setState(() {
      _selectedCategory = category;
      _filteredServices = filtered;
      _selectedService = selectedServ;
      _serviceHistory = history;
      _availableHistoryYears = yearsList;
      _selectedHistoryYear = selectedHistoryYear;
    });
  }

  Future<void> _onServiceChanged(ServiceItem? service) async {
    if (service == null) return;
    final history = await DatabaseHelper.instance.getServicePaymentsHistory(service.id, _selectedCurrency);
    
    final Set<int> yearsSet = {};
    for (final h in history) {
      yearsSet.add(h['anio'] as int);
    }
    final yearsList = yearsSet.toList()..sort((a, b) => b.compareTo(a));

    int? selectedHistoryYear = yearsList.isNotEmpty ? yearsList.first : DateTime.now().year;

    setState(() {
      _selectedService = service;
      _serviceHistory = history;
      _availableHistoryYears = yearsList;
      _selectedHistoryYear = selectedHistoryYear;
    });
  }

  void _changeMonth(int direction) {
    setState(() {
      _currentMonth += direction;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    _loadStatistics(firstLoad: false); // Disable screen loading indicator to prevent scroll resets
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: const PageStorageKey<String>('statistics_scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderWithCurrency(),
          const SizedBox(height: 14),
          _buildSubTabs(),
          const SizedBox(height: 18),
          if (_activeSubTab == 0)
            _buildServiceHistoryCard()
          else
            _buildCategoryDonutCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderWithCurrency() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Estadísticas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_selectedCurrency != 'PEN') {
                    setState(() => _selectedCurrency = 'PEN');
                    _loadStatistics(firstLoad: false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedCurrency == 'PEN' ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soles S/',
                    style: TextStyle(
                      color: _selectedCurrency == 'PEN' ? AppColors.accentDark : AppColors.inkMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: () {
                  if (_selectedCurrency != 'USD') {
                    setState(() => _selectedCurrency = 'USD');
                    _loadStatistics(firstLoad: false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedCurrency == 'USD' ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Dólares \$',
                    style: TextStyle(
                      color: _selectedCurrency == 'USD' ? AppColors.accentDark : AppColors.inkMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSubTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSubTab == 0 ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Servicios',
                  style: TextStyle(
                    color: _activeSubTab == 0 ? AppColors.accentDark : AppColors.inkMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSubTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSubTab == 1 ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Categorías',
                  style: TextStyle(
                    color: _activeSubTab == 1 ? AppColors.accentDark : AppColors.inkMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs() {
    final currencySymbol = _selectedCurrency == 'USD' ? '\$' : 'S/';
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Total del Mes',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$currencySymbol ${_totalMonthExpenses.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Promedio Mensual',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$currencySymbol ${_averageMonthlyExpenses.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDonutCard() {
    final hasData = _categoryExpenses.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Gastos Categoría',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: AppColors.accent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _changeMonth(-1),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${monthName(_currentMonth).substring(0, 3)} ${_currentYear.toString().substring(2)}',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: AppColors.accent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Integrated KPI Cards INSIDE the Category Expenses Card
          _buildKPIs(),
          const SizedBox(height: 20),
          
          if (!hasData)
            _buildChartPlaceholder('Sin pagos registrados en este período.')
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: _getPieSections(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildPieLegend(),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieSections() {
    return List.generate(_categoryExpenses.length, (i) {
      final exp = _categoryExpenses[i];
      final total = (exp['total'] as num).toDouble();
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 28.0 : 20.0;
      final percentage = _totalMonthExpenses > 0 ? (total / _totalMonthExpenses) * 100 : 0.0;

      // Enforce a minimum visual value for very small categories (under 6%) so their slice remains readable
      double visualValue = total;
      if (percentage < 6.0 && _totalMonthExpenses > 0) {
        visualValue = _totalMonthExpenses * 0.06;
      }
      
      // Dynamic distinct curated colors to avoid color collisions
      final color = i < _donutColors.length ? _donutColors[i] : Color(exp['color_value'] as int);

      return PieChartSectionData(
        color: color,
        value: visualValue,
        title: percentage < 4.0 ? '' : '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black54,
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPieLegend() {
    final currencySymbol = _selectedCurrency == 'USD' ? '\$' : 'S/';
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categoryExpenses.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 12),
      itemBuilder: (context, index) {
        final exp = _categoryExpenses[index];
        final total = (exp['total'] as num).toDouble();
        final percentage = _totalMonthExpenses > 0 ? (total / _totalMonthExpenses) * 100 : 0.0;

        // Dynamic distinct curated colors
        final color = index < _donutColors.length ? _donutColors[index] : Color(exp['color_value'] as int);

        return Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exp['name'] as String,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$currencySymbol ${total.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceHistoryCard() {
    final currencySymbol = _selectedCurrency == 'USD' ? '\$' : 'S/';
    
    // Filter history for the selected year
    final filteredHistory = _serviceHistory
        .where((h) => h['anio'] == _selectedHistoryYear)
        .toList();

    // Check if years are available, if empty default to current year
    final availableYears = _availableHistoryYears.isNotEmpty 
        ? _availableHistoryYears 
        : [DateTime.now().year];

    if (_selectedHistoryYear == null || !availableYears.contains(_selectedHistoryYear)) {
      _selectedHistoryYear = availableYears.first;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Historial de Consumo',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (_serviceHistory.isNotEmpty) _buildYearSelector(availableYears),
            ],
          ),
          const SizedBox(height: 16),
          if (_allCategories.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _buildCategorySelector()),
                const SizedBox(width: 10),
                Expanded(child: _buildServiceSelector()),
              ],
            ),
            const SizedBox(height: 22),
          ],
          if (_allCategories.isEmpty)
            _buildChartPlaceholder('No tienes ninguna categoría creada aún.')
          else if (_selectedCategory == null || _filteredServices.isEmpty)
            _buildChartPlaceholder('No hay servicios creados en la categoría seleccionada.')
          else if (_selectedService == null || _serviceHistory.isEmpty)
            _buildChartPlaceholder('Registra pagos en este servicio para ver su evolución.')
          else if (filteredHistory.isEmpty)
            _buildChartPlaceholder('No hay pagos registrados para el año $_selectedHistoryYear.')
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final maxY = _getMaxYHistory(filteredHistory);
                final screenWidth = MediaQuery.of(context).size.width;
                // Calculate dynamic width: clamp between full card inside width and scrollable width
                final chartWidth = (filteredHistory.length * 62.0).clamp(screenWidth - 76.0, 1200.0);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    height: 220,
                    child: Stack(
                      children: [
                        LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY * 1.35,
                            minX: -0.5,
                            maxX: filteredHistory.length - 0.5,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(filteredHistory.length, (i) {
                                  final total = (filteredHistory[i]['total'] as num).toDouble();
                                  return FlSpot(i.toDouble(), total);
                                }),
                                isCurved: true,
                                color: AppColors.warning,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 4.5,
                                    color: AppColors.warning,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.card,
                                  ),
                                ),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            titlesData: const FlTitlesData(show: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                        BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY * 1.35,
                            barTouchData: BarTouchData(
                              enabled: false,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.transparent,
                                tooltipPadding: EdgeInsets.zero,
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '$currencySymbol ${rod.toY.toStringAsFixed(2)}',
                                    TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < filteredHistory.length) {
                                      final item = filteredHistory[idx];
                                      // Display ONLY first 3 letters of month (e.g. Ene, Feb)
                                      final mesShort = monthName(item['mes'] as int).substring(0, 3);
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: Text(
                                          mesShort,
                                          style: TextStyle(
                                            color: AppColors.inkMuted,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: _getBarGroups(filteredHistory, maxY),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  double _getMaxYHistory(List<Map<String, dynamic>> filteredHistory) {
    double maxVal = 0.0;
    for (final h in filteredHistory) {
      final total = (h['total'] as num?)?.toDouble() ?? 0.0;
      if (total > maxVal) maxVal = total;
    }
    return maxVal == 0.0 ? 100.0 : maxVal;
  }

  List<BarChartGroupData> _getBarGroups(List<Map<String, dynamic>> filteredHistory, double maxY) {
    return List.generate(filteredHistory.length, (i) {
      final h = filteredHistory[i];
      final total = (h['total'] as num).toDouble();

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            color: AppColors.accent,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY * 1.2,
              color: AppColors.surface,
            ),
          ),
        ],
        showingTooltipIndicators: const [0],
      );
    });
  }

  Widget _buildYearSelector(List<int> availableYears) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedHistoryYear,
          dropdownColor: AppColors.card,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.accent, size: 20),
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
          onChanged: (year) {
            if (year != null) {
              setState(() {
                _selectedHistoryYear = year;
              });
            }
          },
          items: availableYears.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text('$year'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CategoryItem>(
          value: _selectedCategory,
          isExpanded: true,
          items: _allCategories.map((cat) {
            return DropdownMenuItem<CategoryItem>(
              value: cat,
              child: Text(
                cat.name,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _onCategoryChanged,
          dropdownColor: AppColors.card,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.accent),
        ),
      ),
    );
  }

  Widget _buildServiceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceItem>(
          value: _selectedService,
          isExpanded: true,
          hint: Text(
            'Servicio',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          items: _filteredServices.map((service) {
            return DropdownMenuItem<ServiceItem>(
              value: service,
              child: Text(
                service.name,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _onServiceChanged,
          dropdownColor: AppColors.card,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.accent),
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.border, size: 48),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
