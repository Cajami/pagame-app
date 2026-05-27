import 'package:pagame/models/payment_record.dart';

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.billingCycle,
    this.remindersEnabled = false,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.notify5Days = true,
    this.notifySameDay = true,
    Map<int, Set<int>>? monthsByYear,
    Map<String, List<PaymentRecord>>? paymentsByPeriod,
  }) : monthsByYear = monthsByYear ?? <int, Set<int>>{},
       paymentsByPeriod = paymentsByPeriod ?? <String, List<PaymentRecord>>{};

  final String id;
  final String categoryId;
  final String name;
  final String billingCycle;

  // Reminder configuration fields
  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool notify5Days;
  final bool notifySameDay;

  final Map<int, Set<int>> monthsByYear;
  final Map<String, List<PaymentRecord>> paymentsByPeriod;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoryId,
      'name': name,
      'billing_cycle': billingCycle,
      'reminders_enabled': remindersEnabled ? 1 : 0,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'notify_5_days': notify5Days ? 1 : 0,
      'notify_same_day': notifySameDay ? 1 : 0,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] as String,
      categoryId: map['categoria_id'] as String,
      name: map['name'] as String,
      billingCycle: map['billing_cycle'] as String,
      remindersEnabled: (map['reminders_enabled'] as int? ?? 0) == 1,
      reminderHour: map['reminder_hour'] as int? ?? 8,
      reminderMinute: map['reminder_minute'] as int? ?? 0,
      notify5Days: (map['notify_5_days'] as int? ?? 1) == 1,
      notifySameDay: (map['notify_same_day'] as int? ?? 1) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
