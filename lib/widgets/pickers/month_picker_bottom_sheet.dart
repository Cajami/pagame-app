import 'package:flutter/material.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/date_utils.dart';

Future<int?> showMonthPicker(BuildContext context) async {
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
                    'Selecciona el mes',
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
                              monthName(month),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.inkMuted,
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
