class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.status,
    this.amount,
    required this.paymentDate,
    this.notes,
    this.attachments = const <String>[],
    this.moneda = 'PEN',
  });

  final String id;
  final String status;
  final double? amount;
  final DateTime paymentDate;
  final String? notes;
  final List<String> attachments;
  final String moneda;
}
