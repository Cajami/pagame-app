import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.paymentToEdit != null) {
      _amountController.text = widget.paymentToEdit!.amount?.toString() ?? '';
      _notesController.text = widget.paymentToEdit!.notes ?? '';
      _status = widget.paymentToEdit!.status;
      _paymentDate = widget.paymentToEdit!.paymentDate;
      _attachments.addAll(widget.paymentToEdit!.attachments);
    } else {
      _status = 'Pagado';
      _paymentDate = DateTime.now();
    }
  }

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
    final amount = amountText.isEmpty ? null : double.parse(amountText);

    Navigator.of(context).pop(
      PaymentRecord(
        id: widget.paymentToEdit?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
                  errorBuilder: (context, error, stackTrace) => const Center(
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
                          style: const TextStyle(
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
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(labelText: 'Estado'),
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
                    decoration: const InputDecoration(
                      labelText: 'Monto (opcional)',
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
                      decoration: const InputDecoration(
                        labelText: 'Fecha de pago',
                      ),
                      child: Text(
                        formatDate(_paymentDate),
                        style: const TextStyle(color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
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
