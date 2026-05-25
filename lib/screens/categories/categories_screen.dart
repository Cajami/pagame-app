import 'package:flutter/material.dart';
import 'package:pagame/models/category_item.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/screens/categories/category_services_screen.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/widgets/common/app_background.dart';
import 'package:pagame/widgets/sheets/create_category_sheet.dart';
import 'package:pagame/utils/backup_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedTab = 0;
  final List<CategoryItem> _categories = [];
  final Map<String, List<ServiceItem>> _servicesByCategoryId = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories.clear();
      _categories.addAll(categories);
      for (final cat in categories) {
        _servicesByCategoryId[cat.id] = [];
      }
    });

    for (final cat in categories) {
      final services = await DatabaseHelper.instance.getServicesForCategory(cat.id);
      if (mounted) {
        setState(() {
          _servicesByCategoryId[cat.id] = services;
        });
      }
    }
  }

  void _showPlaceholderMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.ink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }

  Future<void> _openCreateCategorySheet() async {
    final newCategory = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCategorySheet(),
    );

    if (!mounted) {
      return;
    }

    if (newCategory == null) {
      return;
    }

    await DatabaseHelper.instance.insertCategory(newCategory);

    setState(() {
      _categories.insert(0, newCategory);
      _servicesByCategoryId[newCategory.id] = [];
    });

    _showPlaceholderMessage('Categoría "${newCategory.name}" creada.');
  }

  void _openCategoryServices(CategoryItem category) {
    final currentServices = _servicesByCategoryId[category.id] ?? [];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CategoryServicesScreen(
          category: category,
          initialServices: currentServices,
          onServicesChanged: (updatedServices) {
            setState(() {
              _servicesByCategoryId[category.id] = updatedServices;
            });
          },
        ),
      ),
    );
  }

  Future<void> _editCategory(CategoryItem category) async {
    final updatedCategory = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCategorySheet(categoryToEdit: category),
    );

    if (!mounted || updatedCategory == null) {
      return;
    }

    await DatabaseHelper.instance.insertCategory(updatedCategory);

    setState(() {
      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
    });

    _showPlaceholderMessage('Categoría "${updatedCategory.name}" modificada.');
  }

  Future<void> _deleteCategoryAction(CategoryItem category) async {
    final services = _servicesByCategoryId[category.id] ?? [];
    if (services.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: const Text('No se puede eliminar', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          content: const Text(
            'Esta categoría tiene servicios registrados. Elimina primero todos sus servicios para poder borrarla.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido', style: TextStyle(color: AppColors.accent)),
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
        title: const Text('Eliminar categoría', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.name}"?'),
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
      await DatabaseHelper.instance.deleteCategory(category.id);
      setState(() {
        _categories.removeWhere((cat) => cat.id == category.id);
        _servicesByCategoryId.remove(category.id);
      });
      _showPlaceholderMessage('Categoría "${category.name}" eliminada.');
    }
  }

  Widget _buildContent() {
    if (_selectedTab == 0) {
      if (_categories.isEmpty) {
        return _CategoriesEmptyState(
          onCreateCategory: _openCreateCategorySheet,
        );
      }

      return _CategoriesListState(
        categories: _categories,
        servicesByCategoryId: _servicesByCategoryId,
        onOpenCategory: _openCategoryServices,
        onEditCategory: _editCategory,
        onDeleteCategory: _deleteCategoryAction,
      );
    }

    return _SettingsTabState(
      onRefreshCategories: _loadCategories,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _MainHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slideTween = Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic));
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(slideTween),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0 && _categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCreateCategorySheet,
              icon: const Icon(Icons.add),
              label: const Text('Crear categoría'),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (value) {
            setState(() {
              _selectedTab = value;
            });
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder_copy),
              label: 'Categorías',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesEmptyState extends StatelessWidget {
  const _CategoriesEmptyState({required this.onCreateCategory});

  final VoidCallback onCreateCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 110,
            width: 110,
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
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.folder_open, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 22),
          Text(
            'Tus categorías están vacías',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Crea una para agrupar servicios y seguir tus pagos con claridad.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.inkSoft,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _InfoChip(icon: Icons.calendar_month_outlined, text: 'Mensuales'),
              _InfoChip(icon: Icons.receipt_long_outlined, text: 'Pago único'),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateCategory,
              icon: const Icon(Icons.add),
              label: const Text('Crear categoría'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesListState extends StatelessWidget {
  const _CategoriesListState({
    required this.categories,
    required this.servicesByCategoryId,
    required this.onOpenCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  final List<CategoryItem> categories;
  final Map<String, List<ServiceItem>> servicesByCategoryId;
  final ValueChanged<CategoryItem> onOpenCategory;
  final ValueChanged<CategoryItem> onEditCategory;
  final ValueChanged<CategoryItem> onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      itemBuilder: (context, index) {
        final category = categories[index];
        final serviceCount = servicesByCategoryId[category.id]?.length ?? 0;
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
              onTap: () => onOpenCategory(category),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: Colors.white),
              ),
              title: Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                serviceCount == 0
                    ? 'Sin servicios registrados'
                    : '$serviceCount servicio${serviceCount == 1 ? '' : 's'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
                color: AppColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEditCategory(category);
                  } else if (value == 'delete') {
                    onDeleteCategory(category);
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
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: categories.length,
    );
  }
}

class _MainHeader extends StatelessWidget {
  const _MainHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            const HeaderBackground(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/logo_pagame1.png',
                          height: 52,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Text(
                            'Págame',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organiza tus servicios, guarda tus recibos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFBBD6EA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3446),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF244E66)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFBFE4F2)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFE8F4FB),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabState extends StatefulWidget {
  const _SettingsTabState({required this.onRefreshCategories});

  final VoidCallback onRefreshCategories;

  @override
  State<_SettingsTabState> createState() => _SettingsTabStateState();
}

class _SettingsTabStateState extends State<_SettingsTabState> {
  bool _isProcessing = false;

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isProcessing = true;
    });

    final success = await BackupHelper.exportBackup();

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Copia de seguridad exportada con éxito.' 
                  : 'No se pudo exportar la copia de seguridad.',
            ),
          ),
        );
    }
  }

  Future<void> _handleImport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Importar copia de seguridad', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
        content: const Text(
          'Al importar, los datos de la copia de seguridad se combinarán con tu información actual sin borrar nada. ¿Deseas continuar?',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    final error = await BackupHelper.importBackup();

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      if (error == null) {
        widget.onRefreshCategories();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Copia de seguridad importada y restaurada con éxito.'),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajustes del Sistema',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          
          // Card 1: Local Storage
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1A18C1B5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storage_rounded, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Almacenamiento Local',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tus datos y archivos adjuntos se guardan de forma 100% segura y privada en este dispositivo.',
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 2: Google Drive integration (Future)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Sincronización en la Nube',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRÓXIMAMENTE',
                              style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Copia de seguridad y sincronización automática en tu cuenta de Google Drive.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Card 3: Backups Panel
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x1A18C1B5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Copia de Seguridad Completa',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Exporta todo tu historial de pagos, categorías y archivos físicos (imágenes y PDFs) a un archivo ZIP consolidado, o restáuralos en cualquier momento sin perder tu información actual.',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _handleExport,
                          icon: const Icon(Icons.backup_rounded),
                          label: const Text('Exportar datos y archivos'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleImport,
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Importar copia de seguridad'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Card 4: Developer Credits
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1A18C1B5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.terminal_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desarrollador',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'JavierSoft',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                // GitHub Button
                InkWell(
                  onTap: () => _launchURL('https://github.com/cajami'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.code_rounded, color: AppColors.inkSoft, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'github.com/cajami',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded, color: AppColors.inkMuted, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Email Button
                InkWell(
                  onTap: () => _launchURL('mailto:javier2315@gmail.com'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alternate_email_rounded, color: AppColors.inkSoft, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'javier2315@gmail.com',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded, color: AppColors.inkMuted, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
