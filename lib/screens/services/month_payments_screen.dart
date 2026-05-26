import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pagame/models/payment_record.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/utils/date_utils.dart';
import 'package:pagame/widgets/common/app_background.dart';
import 'package:pagame/widgets/sheets/create_payment_sheet.dart';
import 'package:pagame/widgets/sheets/show_attachments_sheet.dart';

class MonthPaymentsScreen extends StatefulWidget {
  const MonthPaymentsScreen({
    super.key,
    required this.service,
    required this.year,
    required this.month,
  });

  final ServiceItem service;
  final int year;
  final int month;

  @override
  State<MonthPaymentsScreen> createState() => _MonthPaymentsScreenState();
}

class _MonthPaymentsScreenState extends State<MonthPaymentsScreen> {
  String get _periodKey => '${widget.year}-${widget.month}';
  
  final List<PaymentRecord> _paymentsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final monthId = '${widget.service.id}_${widget.year}_${widget.month}';
    final dbPayments = await DatabaseHelper.instance.getPaymentsForMonth(monthId: monthId);
    
    if (mounted) {
      setState(() {
        _paymentsList.clear();
        _paymentsList.addAll(dbPayments);
        widget.service.paymentsByPeriod[_periodKey] = _paymentsList;
        _isLoading = false;
      });
    }
  }

  Future<void> _createPayment() async {
    final payment = await showModalBottomSheet<PaymentRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePaymentSheet(),
    );

    if (!mounted || payment == null) {
      return;
    }

    final monthId = '${widget.service.id}_${widget.year}_${widget.month}';

    // Save to SQLite database
    await DatabaseHelper.instance.insertPayment(monthId, payment);

    if (!mounted) {
      return;
    }

    setState(() {
      _paymentsList.insert(0, payment);
      widget.service.paymentsByPeriod[_periodKey] = _paymentsList;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Pago registrado.'),
        ),
      );
  }

  Future<void> _editPayment(PaymentRecord payment) async {
    final updatedPayment = await showModalBottomSheet<PaymentRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePaymentSheet(paymentToEdit: payment),
    );

    if (!mounted || updatedPayment == null) {
      return;
    }

    await DatabaseHelper.instance.updatePayment(updatedPayment);

    setState(() {
      final index = _paymentsList.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        _paymentsList[index] = updatedPayment;
        widget.service.paymentsByPeriod[_periodKey] = _paymentsList;
      }
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Pago modificado.'),
        ),
      );
  }

  Future<void> _deletePaymentAction(PaymentRecord payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Eliminar pago', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que deseas eliminar este pago? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.inkMuted)),
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
      await DatabaseHelper.instance.deletePayment(payment.id);
      setState(() {
        _paymentsList.removeWhere((p) => p.id == payment.id);
        widget.service.paymentsByPeriod[_periodKey] = _paymentsList;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Pago eliminado.'),
          ),
        );
    }
  }

  bool _isImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  Widget _buildAttachmentsListPreview(BuildContext context, PaymentRecord payment) {
    final paths = payment.attachments;
    if (paths.isEmpty) return const SizedBox.shrink();

    final count = paths.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => ShowAttachmentsSheet(
              payment: payment,
              service: widget.service,
              year: widget.year,
              monthName: monthName(widget.month),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_file_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  count == 1 ? '1 archivo adjunto' : '$count archivos adjuntos',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Circular mini preview stack (avatar-like)
              SizedBox(
                height: 28,
                width: (count > 3 ? 3 : count) * 20.0 + 8.0,
                child: Stack(
                  children: List.generate(count > 3 ? 3 : count, (index) {
                    final path = paths[index];
                    final isImg = _isImage(path);
                    return Positioned(
                      left: index * 20.0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card, width: 1.5),
                          color: AppColors.surface,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isImg
                            ? Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 12,
                                  color: AppColors.inkMuted,
                                ),
                              )
                            : const Icon(
                                Icons.picture_as_pdf_outlined,
                                color: Colors.redAccent,
                                size: 12,
                              ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.inkMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payments = _paymentsList;
    final monthNameValue = monthName(widget.month);

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
            Text(' - $monthNameValue ${widget.year}'),
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
      floatingActionButton: !_isLoading && payments.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createPayment,
              icon: const Icon(Icons.add),
              label: const Text('Registrar pago'),
            )
          : null,
      body: Stack(
        children: [
          const AppBackground(),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : payments.isEmpty
                  ? _MonthPaymentsEmptyState(onCreatePayment: _createPayment)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                      itemCount: payments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        final hasNotes = (payment.notes ?? '').isNotEmpty;
                        final dateAndNotes = hasNotes
                            ? '${formatDate(payment.paymentDate)} · ${payment.notes}'
                            : formatDate(payment.paymentDate);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
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
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppColors.accent,
                                  ),
                                ),
                                title: Text(
                                  payment.amount == null
                                      ? payment.status
                                      : 'S/ ${payment.amount!.toStringAsFixed(2)} · ${payment.status}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                subtitle: Text(
                                  dateAndNotes,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
                                  color: AppColors.card,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editPayment(payment);
                                    } else if (value == 'delete') {
                                      _deletePaymentAction(payment);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, color: AppColors.ink, size: 20),
                                          SizedBox(width: 8),
                                          Text('Editar', style: TextStyle(color: AppColors.ink)),
                                        ],
                                      ),
                                    ),
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
                              if (payment.attachments.isNotEmpty)
                                _buildAttachmentsListPreview(context, payment),
                            ],
                          ),
                        );
                      },
                    ),
        ],
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
              Icons.payments_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Sin pagos este mes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Registra el primer pago para mantener el historial.',
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
              onPressed: onCreatePayment,
              icon: const Icon(Icons.add),
              label: const Text('Registrar pago'),
            ),
          ),
        ],
      ),
    );
  }
}
