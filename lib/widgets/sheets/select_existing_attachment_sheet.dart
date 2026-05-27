import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pagame/models/category_item.dart';
import 'package:pagame/models/service_item.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/utils/database_helper.dart';

class SelectExistingAttachmentSheet extends StatefulWidget {
  const SelectExistingAttachmentSheet({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  final String serviceId;
  final String serviceName;

  @override
  State<SelectExistingAttachmentSheet> createState() =>
      _SelectExistingAttachmentSheetState();
}

class _SelectExistingAttachmentSheetState
    extends State<SelectExistingAttachmentSheet> {
  // Tabs: 'service' (Este Servicio), 'recent' (Recientes), 'browse' (Por Servicio)
  String _activeTab = 'service';

  bool _isLoading = true;
  List<String> _attachments = [];

  // Dropdown filter states for 'browse'
  List<CategoryItem> _categories = [];
  List<ServiceItem> _services = [];
  CategoryItem? _selectedCategory;
  ServiceItem? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadTabAttachments();
    
    // Load categories for the "browse" filter in background
    try {
      final dbCategories = await DatabaseHelper.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = dbCategories;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadTabAttachments() async {
    setState(() => _isLoading = true);
    try {
      List<String> loaded = [];
      if (_activeTab == 'service') {
        loaded = await DatabaseHelper.instance
            .getUniqueAttachmentsForService(widget.serviceId);
      } else if (_activeTab == 'recent') {
        loaded = await DatabaseHelper.instance.getAllUniqueAttachments();
      } else if (_activeTab == 'browse' && _selectedService != null) {
        loaded = await DatabaseHelper.instance
            .getUniqueAttachmentsForService(_selectedService!.id);
      }
      if (mounted) {
        setState(() {
          _attachments = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attachments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onCategoryChanged(CategoryItem? category) async {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _selectedService = null;
      _services = [];
      _attachments = [];
      _isLoading = true;
    });

    try {
      final dbServices =
          await DatabaseHelper.instance.getServicesForCategory(category.id);
      if (mounted) {
        setState(() {
          _services = dbServices;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onServiceChanged(ServiceItem? service) {
    if (service == null) return;
    setState(() {
      _selectedService = service;
    });
    _loadTabAttachments();
  }

  void _selectTab(String tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _attachments = [];
    });
    _loadTabAttachments();
  }

  bool _isImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.accentDark : AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.accentDark : AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 38,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin comprobantes',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _activeTab == 'service'
                  ? 'No se encontraron comprobantes registrados en este servicio.'
                  : _activeTab == 'recent'
                      ? 'No hay imágenes guardadas en ningún pago de la aplicación.'
                      : 'Selecciona una categoría y servicio para explorar sus recibos.',
              style: TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final path = _attachments[index];
          final isImg = _isImage(path);
          final fileName = path.split('/').last.split('\\').last;

          return GestureDetector(
            onTap: () => Navigator.of(context).pop(path),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
                color: AppColors.card,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: isImg
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
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
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              fileName,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              'Elegir comprobante guardado',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona un recibo registrado anteriormente para vincularlo a este pago sin duplicar espacio.',
              style: TextStyle(
                color: AppColors.inkSoft,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Custom Tab Chips row
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    'service',
                    widget.serviceName,
                    Icons.subscriptions_outlined,
                  ),
                  _buildTabButton(
                    'recent',
                    'Recientes',
                    Icons.history_toggle_off_rounded,
                  ),
                  _buildTabButton(
                    'browse',
                    'Por Servicio',
                    Icons.search_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Browse filters panel
            if (_activeTab == 'browse') ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CategoryItem>(
                      initialValue: _selectedCategory,
                      dropdownColor: AppColors.card,
                      style: TextStyle(color: AppColors.ink, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ServiceItem>(
                      key: ValueKey(_selectedCategory?.id),
                      initialValue: _selectedService,
                      disabledHint: Text('Primero elige cat.', style: TextStyle(color: AppColors.inkMuted, fontSize: 11)),
                      dropdownColor: AppColors.card,
                      style: TextStyle(color: AppColors.ink, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Servicio',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _services
                          .map((srv) => DropdownMenuItem(
                                value: srv,
                                child: Text(srv.name),
                              ))
                          .toList(),
                      onChanged: _onServiceChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            // Main body
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_attachments.isEmpty)
              _buildEmptyState()
            else
              _buildAttachmentsGrid(),
          ],
        ),
      ),
    );
  }
}
