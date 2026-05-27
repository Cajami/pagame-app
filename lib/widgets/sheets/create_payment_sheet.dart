import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pagame/models/payment_record.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/date_utils.dart';
import 'package:pagame/widgets/sheets/select_existing_attachment_sheet.dart';

class CreatePaymentSheet extends StatefulWidget {
  const CreatePaymentSheet({
    super.key,
    required this.serviceId,
    required this.serviceName,
    this.paymentToEdit,
  });

  final String serviceId;
  final String serviceName;
  final PaymentRecord? paymentToEdit;

  @override
  State<CreatePaymentSheet> createState() => _CreatePaymentSheetState();
}

class _CreatePaymentSheetState extends State<CreatePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _attachments = <String>[];

  late String _status;
  late DateTime _paymentDate;
  late String _moneda;

  @override
  void initState() {
    super.initState();
    _status = 'Pagado';
    if (widget.paymentToEdit != null) {
      final amt = widget.paymentToEdit!.amount;
      _amountController.text = amt != null ? amt.toStringAsFixed(2) : '';
      _notesController.text = widget.paymentToEdit!.notes ?? '';
      _paymentDate = widget.paymentToEdit!.paymentDate;
      _attachments.addAll(widget.paymentToEdit!.attachments);
      _moneda = widget.paymentToEdit!.moneda;
    } else {
      _paymentDate = DateTime.now();
      _moneda = 'PEN';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate.isAfter(now) ? now : _paymentDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: now,
    );

    if (selectedDate != null) {
      setState(() {
        _paymentDate = selectedDate;
      });
    }
  }

  Future<void> _pickAttachments() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'pdf', // Restricted only to images and PDFs
      ],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    // Extract paths which are always available on mobile
    final filePaths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .toList();

    if (filePaths.isEmpty) {
      return;
    }

    setState(() {
      for (final path in filePaths) {
        if (!_attachments.contains(path)) {
          _attachments.add(path);
        }
      }
    });
  }

  Future<void> _takePhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          if (!_attachments.contains(photo.path)) {
            _attachments.add(photo.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _selectExistingAttachment() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
    final selectedPath = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectExistingAttachmentSheet(
        serviceId: widget.serviceId,
        serviceName: widget.serviceName,
      ),
    );

    if (!mounted || selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    setState(() {
      if (!_attachments.contains(selectedPath)) {
        _attachments.add(selectedPath);
      }
    });
  }

  void _removeAttachment(String path) {
    setState(() {
      _attachments.remove(path);
    });
  }

  bool _isImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.parse(amountText);

    final notesText = _notesController.text.trim();
    final capitalizedNotes = notesText.isNotEmpty
        ? '${notesText[0].toUpperCase()}${notesText.substring(1)}'
        : null;

    Navigator.of(context).pop(
      PaymentRecord(
        id: widget.paymentToEdit?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        status: _status,
        amount: amount,
        paymentDate: _paymentDate,
        notes: capitalizedNotes,
        attachments: List<String>.from(_attachments),
        moneda: _moneda,
      ),
    );
  }

  Widget _buildAttachmentThumbnail(String path) {
    final isImg = _isImage(path);
    final fileName = path.split('/').last.split('\\').last;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
            color: AppColors.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: isImg
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.inkMuted,
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeAttachment(path),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.paymentToEdit == null ? 'Nuevo pago' : 'Editar pago',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            AtmAmountFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            hintText: '0.00',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty || value == '0.00') {
                              return 'El monto es obligatorio';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Ingresa un monto válido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _moneda = 'PEN'),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _moneda == 'PEN' ? AppColors.accent : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'S/',
                                      style: TextStyle(
                                        color: _moneda == 'PEN' ? AppColors.accentDark : AppColors.inkMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _moneda = 'USD'),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _moneda == 'USD' ? AppColors.accent : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '\$',
                                      style: TextStyle(
                                        color: _moneda == 'USD' ? AppColors.accentDark : AppColors.inkMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de pago',
                      ),
                      child: Text(
                        formatDate(_paymentDate),
                        style: TextStyle(color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return Text(
                        '$currentLength de $maxLength',
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickAttachments,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file_rounded, size: 20),
                              SizedBox(height: 4),
                              Text(
                                'Adjuntar',
                                style: TextStyle(fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _takePhoto,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 20),
                              SizedBox(height: 4),
                              Text(
                                'Tomar foto',
                                style: TextStyle(fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectExistingAttachment,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_rounded, size: 20),
                              SizedBox(height: 4),
                              Text(
                                'Existente',
                                style: TextStyle(fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: _attachments
                            .map((path) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildAttachmentThumbnail(path),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(widget.paymentToEdit == null ? 'Guardar pago' : 'Guardar cambios'),
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

class AtmAmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final onlyDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (onlyDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final cents = double.parse(onlyDigits);
    final amount = cents / 100.0;
    final formatted = amount.toStringAsFixed(2);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
