import 'package:flutter/material.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/utils/notification_helper.dart';

class ConfigureRemindersSheet extends StatefulWidget {
  const ConfigureRemindersSheet({
    super.key,
    required this.service,
  });

  final ServiceItem service;

  @override
  State<ConfigureRemindersSheet> createState() => _ConfigureRemindersSheetState();
}

class _ConfigureRemindersSheetState extends State<ConfigureRemindersSheet> {
  late bool _remindersEnabled;
  late int _reminderHour;
  late int _reminderMinute;
  late bool _notify5Days;
  late bool _notifySameDay;

  @override
  void initState() {
    super.initState();
    _remindersEnabled = widget.service.remindersEnabled;
    _reminderHour = widget.service.reminderHour;
    _reminderMinute = widget.service.reminderMinute;
    _notify5Days = widget.service.notify5Days;
    _notifySameDay = widget.service.notifySameDay;
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (BuildContext context, Widget? child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            timePickerTheme: baseTheme.timePickerTheme.copyWith(
              dialTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  String _formatTime() {
    final hourStr = _reminderHour.toString().padLeft(2, '0');
    final minuteStr = _reminderMinute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr HRS';
  }

  Future<void> _save() async {
    final updatedService = ServiceItem(
      id: widget.service.id,
      categoryId: widget.service.categoryId,
      name: widget.service.name,
      billingCycle: widget.service.billingCycle,
      remindersEnabled: _remindersEnabled,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      notify5Days: _notify5Days,
      notifySameDay: _notifySameDay,
      monthsByYear: widget.service.monthsByYear,
      paymentsByPeriod: widget.service.paymentsByPeriod,
    );

    // 1. Guardar en la base de datos local SQLite
    await DatabaseHelper.instance.updateService(updatedService);

    // 2. Cerrar el modal inmediatamente para una respuesta instantánea
    if (mounted) {
      Navigator.of(context).pop(updatedService);
    }

    // 3. Programar o limpiar recordatorios en segundo plano de manera no-bloqueante
    NotificationHelper.scheduleServiceReminders(updatedService).catchError((e) {
      debugPrint('Error programando recordatorios en background: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isQuincena = widget.service.billingCycle.toLowerCase().contains('quincena');
    final switchTitle = isQuincena ? 'Activar alertas de quincena de mes' : 'Activar alertas de fin de mes';
    final option1Title = isQuincena ? 'A 5 días de quincena de mes' : 'A 5 días del fin de mes';
    final option2Title = isQuincena ? 'El mismo día de quincena de mes' : 'El mismo día del fin de mes';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1A18C1B5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_active_outlined,
                        color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recordatorios offline',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          widget.service.name,
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Switch principal
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: Text(
                    switchTitle,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: const Text(
                    'Recibe avisos nativos automáticos sin consumir internet ni batería.',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  value: _remindersEnabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: (value) {
                    setState(() {
                      _remindersEnabled = value;
                    });
                  },
                ),
              ),
              
              if (_remindersEnabled) ...[
                const SizedBox(height: 16),
                // Selector de Hora
                InkWell(
                  onTap: _selectTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: AppColors.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hora del recordatorio',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _formatTime(),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                // Opciones de alerta
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                         title: Text(
                          option1Title,
                          style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        activeColor: AppColors.accent,
                        value: _notify5Days,
                        onChanged: (val) {
                          if (val != null) setState(() => _notify5Days = val);
                        },
                      ),

                      Divider(color: AppColors.border, height: 1),
                      CheckboxListTile(
                         title: Text(
                          option2Title,
                          style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        activeColor: AppColors.accent,
                        value: _notifySameDay,
                        onChanged: (val) {
                          if (val != null) setState(() => _notifySameDay = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Guardar configuración'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
