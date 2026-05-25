import 'package:pagame/models/payment_record.dart';

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.type,
    required this.billingCycle,
    Map<int, Set<int>>? monthsByYear,
    Map<String, List<PaymentRecord>>? paymentsByPeriod,
  }) : monthsByYear = monthsByYear ?? <int, Set<int>>{},
       paymentsByPeriod = paymentsByPeriod ?? <String, List<PaymentRecord>>{};

  final String id;
  final String categoryId;
  final String name;
  final String type;
  final String billingCycle;
  final Map<int, Set<int>> monthsByYear;
  final Map<String, List<PaymentRecord>> paymentsByPeriod;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoryId,
      'name': name,
      'type': type,
      'billing_cycle': billingCycle,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] as String,
      categoryId: map['categoria_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      billingCycle: map['billing_cycle'] as String,
    );
  }
}
