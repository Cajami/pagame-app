import 'package:flutter/material.dart';
import 'package:pagame/theme/app_colors.dart';

Future<int?> showYearPicker(BuildContext context, {List<int> existingYears = const []}) async {
  const years = <int>[2025, 2026, 2027, 2028];
  final current = DateTime.now().year.clamp(2025, 2028);
  
  // Default to current year if not added, otherwise search forward for the first available year
  int defaultYear = current;
  if (existingYears.contains(current)) {
    defaultYear = years.firstWhere(
      (y) => !existingYears.contains(y),
      orElse: () => current,
    );
  }
  int selectedYear = defaultYear;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final controller = FixedExtentScrollController(
        initialItem: years.indexOf(selectedYear),
      );

      return StatefulBuilder(
        builder: (context, setModalState) {
          final isCurrentYearExisting = existingYears.contains(selectedYear);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, -12),
                ),
              ],
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecciona el año',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
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
                          final isExisting = existingYears.contains(year);
                          final selected = year == selectedYear;

                          Color textColor = AppColors.inkMuted;
                          if (isExisting) {
                            textColor = AppColors.inkMuted.withValues(alpha: 0.35);
                          } else if (selected) {
                            textColor = AppColors.accent;
                          }

                          return Center(
                            child: Text(
                              isExisting ? '$year (Ya agregado)' : year.toString(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: textColor,
                                fontWeight: selected && !isExisting
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
                      onPressed: isCurrentYearExisting ? null : () => Navigator.of(context).pop(selectedYear),
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
