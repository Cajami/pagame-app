import 'package:flutter/material.dart';
import 'package:pagame/models/category_item.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/screens/services/service_timeline_screen.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/widgets/common/app_background.dart';
import 'package:pagame/widgets/sheets/create_service_sheet.dart';
import 'package:pagame/widgets/sheets/configure_reminders_sheet.dart';

class CategoryServicesScreen extends StatefulWidget {
  const CategoryServicesScreen({
    super.key,
    required this.category,
    required this.initialServices,
    required this.onServicesChanged,
  });

  final CategoryItem category;
  final List<ServiceItem> initialServices;
  final ValueChanged<List<ServiceItem>> onServicesChanged;

  @override
  State<CategoryServicesScreen> createState() =>
      _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  late final List<ServiceItem> _services = List<ServiceItem>.from(
    widget.initialServices,
  );

  void _sortServices() {
    _services.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _openServiceTimeline(ServiceItem service) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ServiceTimelineScreen(service: service),
      ),
    );

    if (mounted) {
      setState(() {});
      widget.onServicesChanged(_services);
    }
  }

  Future<void> _editService(ServiceItem service) async {
    final updatedService = await showModalBottomSheet<ServiceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateServiceSheet(
        categoryId: widget.category.id,
        serviceToEdit: service,
      ),
    );

    if (!mounted || updatedService == null) {
      return;
    }

    await DatabaseHelper.instance.updateService(updatedService);

    setState(() {
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = updatedService;
        _sortServices();
      }
    });
    widget.onServicesChanged(_services);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('Servicio "${updatedService.name}" modificado.'),
        ),
      );
  }

  Future<void> _deleteServiceAction(ServiceItem service) async {
    if (service.monthsByYear.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: Text('No se puede eliminar', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          content: Text(
            'Este servicio tiene años registrados. Elimina primero todos sus años para poder borrarlo.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text('Eliminar servicio', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar el servicio "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.inkMuted)),
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
      await DatabaseHelper.instance.deleteService(service.id);
      if (!mounted) return;
      setState(() {
        _services.removeWhere((s) => s.id == service.id);
      });
      widget.onServicesChanged(_services);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            content: Text('Servicio "${service.name}" eliminado.'),
          ),
        );
    }
  }

  Future<void> _openConfigureReminders(ServiceItem service) async {
    final updated = await showModalBottomSheet<ServiceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfigureRemindersSheet(service: service),
    );

    if (updated != null && mounted) {
      setState(() {
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          _services[index] = updated;
        }
      });
      widget.onServicesChanged(_services);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Configuración de alertas guardada.'),
          ),
        );
    }
  }

  Future<void> _openCreateServiceSheet() async {
    final newService = await showModalBottomSheet<ServiceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateServiceSheet(categoryId: widget.category.id),
    );

    if (!mounted) {
      return;
    }

    if (newService == null) {
      return;
    }

    await DatabaseHelper.instance.insertService(newService);

    if (!mounted) {
      return;
    }

    setState(() {
      _services.add(newService);
      _sortServices();
    });
    widget.onServicesChanged(_services);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.ink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Servicio "${newService.name}" creado.')),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const HeaderBackground(),
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Volver al Inicio',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      floatingActionButton: _services.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCreateServiceSheet,
              icon: const Icon(Icons.add),
              label: const Text('Crear servicio'),
            )
          : null,
      body: Stack(
        children: [
          const AppBackground(),
          _services.isEmpty
              ? _ServicesEmptyState(onCreateService: _openCreateServiceSheet)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: ListTile(
                          onTap: () => _openServiceTimeline(service),
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
                            child: Icon(
                              service.billingCycle.toLowerCase().contains('quincena')
                                  ? Icons.event_repeat_rounded
                                  : Icons.calendar_month_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Tooltip(
                                  message: service.remindersEnabled
                                      ? 'Alertas activadas'
                                      : 'Alertas desactivadas',
                                  child: Icon(
                                    service.remindersEnabled
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_off_outlined,
                                    color: service.remindersEnabled
                                        ? AppColors.accent
                                        : AppColors.inkMuted,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            service.billingCycle.contains('Quincena')
                                ? 'Quincena'
                                : service.billingCycle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
                            color: AppColors.card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editService(service);
                              } else if (value == 'delete') {
                                _deleteServiceAction(service);
                              } else if (value == 'reminders') {
                                _openConfigureReminders(service);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'reminders',
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined, color: AppColors.ink, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Configurar Alertas', style: TextStyle(color: AppColors.ink)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, color: AppColors.ink, size: 20),
                                    const SizedBox(width: 8),
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
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: _services.length,
                ),
        ],
      ),
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState({required this.onCreateService});

  final VoidCallback onCreateService;

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
              Icons.subscriptions_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Sin servicios en esta categoría',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Agrega el primero y define su frecuencia de cobro.',
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
              onPressed: onCreateService,
              icon: const Icon(Icons.add),
              label: const Text('Crear servicio'),
            ),
          ),
        ],
      ),
    );
  }
}
