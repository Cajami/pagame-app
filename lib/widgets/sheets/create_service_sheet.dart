import 'package:flutter/material.dart';
import 'package:pagame/models/payment_record.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/theme/app_colors.dart';

class CreateServiceSheet extends StatefulWidget {
  const CreateServiceSheet({
    super.key,
    required this.categoryId,
    this.serviceToEdit,
    this.existingServices = const [],
  });

  final String categoryId;
  final ServiceItem? serviceToEdit;
  final List<ServiceItem> existingServices;

  @override
  State<CreateServiceSheet> createState() => _CreateServiceSheetState();
}

class _CreateServiceSheetState extends State<CreateServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late String _billingCycle;

  @override
  void initState() {
    super.initState();
    if (widget.serviceToEdit != null) {
      _nameController.text = widget.serviceToEdit!.name;
      _billingCycle = widget.serviceToEdit!.billingCycle == 'Sin vencimiento'
          ? 'Fin de mes'
          : widget.serviceToEdit!.billingCycle;
      // Handle backward compatibility for old "Quincena (día 15)" values
      if (_billingCycle.contains('Quincena')) {
        _billingCycle = 'Quincena';
      }
    } else {
      _billingCycle = 'Fin de mes';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final capitalizedName = name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : name;

    Navigator.of(context).pop(
      ServiceItem(
        id: widget.serviceToEdit?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        categoryId: widget.categoryId,
        name: capitalizedName,
        billingCycle: _billingCycle,
        monthsByYear: widget.serviceToEdit?.monthsByYear ?? <int, Set<int>>{},
        paymentsByPeriod: widget.serviceToEdit?.paymentsByPeriod ?? <String, List<PaymentRecord>>{},
      ),
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
                    widget.serviceToEdit == null ? 'Nuevo servicio' : 'Editar servicio',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ejemplo: Prime Video, Agua, Luz, YouTube Premium, etc.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                   TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 20,
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
                      labelText: 'Nombre del servicio',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del servicio es obligatorio';
                      }
                      final name = value.trim();
                      if (name.length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      if (name.length > 20) {
                        return 'El nombre no puede exceder los 20 caracteres';
                      }
                      final capitalizedName = name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : name;
                      final exists = widget.existingServices.any((s) {
                        if (widget.serviceToEdit != null && s.id == widget.serviceToEdit!.id) {
                          return false;
                        }
                        return s.name.toLowerCase() == capitalizedName.toLowerCase();
                      });
                      if (exists) {
                        return 'Nombre ya registrado';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _billingCycle,
                    dropdownColor: AppColors.card,
                    style: TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia de cobro',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Quincena',
                        child: Text('Quincena'),
                      ),
                      DropdownMenuItem(
                        value: 'Fin de mes',
                        child: Text('Fin de mes'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _billingCycle = value;
                      });
                    },
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(widget.serviceToEdit == null ? 'Guardar servicio' : 'Guardar cambios'),
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
