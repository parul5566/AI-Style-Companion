/// Wardrobe screen — list items, filter, search, add/edit, AI upload.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models/wardrobe_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _searchCtrl = TextEditingController();
  List<WardrobeItem> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _activeCategory;
  bool _showFavoritesOnly = false;
  final _picker = ImagePicker();

  // Categories for the filter bar
  final _categories = [
    'Tops', 'Bottoms', 'Outerwear', 'Dresses', 'Footwear',
    'Accessories', 'Bags', 'Suits', 'Knitwear',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final json = await ApiClient.listWardrobeItems(
        category: _activeCategory,
        isFavorite: _showFavoritesOnly ? true : null,
        search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      );
      _items = json.map((e) => WardrobeItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = 'Failed to load wardrobe items.';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (photo == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(width: 20),
              Text('AI tagging your item...'),
            ],
          ),
        ),
      );
      final json = await ApiClient.uploadWardrobeItem(photo.path);
      Navigator.pop(context); // dismiss dialog
      final item = WardrobeItem.fromJson(json);
      setState(() => _items.insert(0, item));
      if (mounted) showAppSnackBar(context, 'Item added with AI tagging!');
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(context, 'Upload failed. Try adding manually.', isError: true);
      }
    }
  }

  Future<void> _toggleFavorite(WardrobeItem item) async {
    try {
      await ApiClient.updateWardrobeItem(item.id, {'is_favorite': !item.isFavorite});
      setState(() {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx >= 0) {
          _items[idx] = WardrobeItem(
            id: item.id, userId: item.userId, name: item.name, category: item.category,
            subcategory: item.subcategory, colorPrimary: item.colorPrimary,
            colorSecondary: item.colorSecondary, pattern: item.pattern,
            fabric: item.fabric, brand: item.brand, formalityLevel: item.formalityLevel,
            season: item.season, imagePath: item.imagePath, aiTags: item.aiTags,
            isFavorite: !item.isFavorite, timesWorn: item.timesWorn,
            lastWornDate: item.lastWornDate, purchasePrice: item.purchasePrice,
            createdAt: item.createdAt,
          );
        }
      });
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to update', isError: true);
    }
  }

  Future<void> _markAsWorn(WardrobeItem item) async {
    try {
      final json = await ApiClient.markItemWorn(item.id);
      final updated = WardrobeItem.fromJson(json);
      setState(() {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
      if (mounted) showAppSnackBar(context, 'Marked as worn today!');
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to update', isError: true);
    }
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiClient.deleteWardrobeItem(item.id);
      setState(() => _items.removeWhere((i) => i.id == item.id));
      if (mounted) showAppSnackBar(context, 'Item deleted');
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to delete', isError: true);
    }
  }

  void _showAddEditDialog([WardrobeItem? item]) {
    showDialog(
      context: context,
      builder: (_) => AddEditItemDialog(item: item, onSaved: () {
        _loadItems();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wardrobe')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search wardrobe...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () { _searchCtrl.clear(); _loadItems(); },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadItems(),
            ),
          ),

          // Category filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  final isAll = _activeCategory == null;
                  return _filterChip('All', isAll, () {
                    setState(() { _activeCategory = null; });
                    _loadItems();
                  });
                }
                final cat = _categories[i - 1];
                final isActive = _activeCategory == cat;
                return _filterChip(cat, isActive, () {
                  setState(() { _activeCategory = isActive ? null : cat; });
                  _loadItems();
                });
              },
            ),
          ),

          // Favorite toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('★ Favorites'),
                  selected: _showFavoritesOnly,
                  onSelected: (v) {
                    setState(() => _showFavoritesOnly = v);
                    _loadItems();
                  },
                  selectedColor: AppTheme.accent,
                ),
                const Spacer(),
                Text('${_items.length} items',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: _isLoading
                ? const LoadingSpinner()
                : _error != null
                    ? ErrorDisplay(message: _error!, onRetry: _loadItems)
                    : _items.isEmpty
                        ? EmptyState(
                            title: 'No Items Found',
                            subtitle: 'Add your first item or change filters.',
                            icon: Icons.checkroom_outlined,
                            onAction: _pickAndUploadImage,
                            actionLabel: 'Add Item',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadItems,
                            color: AppTheme.primary,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (ctx, i) => _buildItemCard(_items[i]),
                            ),
                          ),
          ),
        ],
      ),

      // FAB for adding items
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'manual_add',
            onPressed: () => _showAddEditDialog(),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ai_upload',
            onPressed: _pickAndUploadImage,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('AI Upload'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          )),
        ),
      ),
    );
  }

  Widget _buildItemCard(WardrobeItem item) {
    return GlassCard(
      onTap: () => _showAddEditDialog(item),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: item.imagePath != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        AppConfig.baseUrl.replaceAll('/api', '') + (item.imagePath ?? ''),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(item),
                      ),
                    )
                  : _buildImagePlaceholder(item),
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(item.category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Row(
                    children: [
                      if (item.colorPrimary != null)
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: _parseColor(item.colorPrimary),
                            shape: BoxShape.circle,
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _toggleFavorite(item),
                        child: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16, color: item.isFavorite ? AppTheme.accent : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _markAsWorn(item),
                        child: Icon(Icons.check_circle_outline, size: 16,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _deleteItem(item),
                        child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(WardrobeItem item) {
    return Center(
      child: Icon(
        _categoryIcon(item.category),
        size: 40,
        color: AppTheme.primary.withOpacity(0.5),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tops': return Icons.checkroom;
      case 'bottoms': return Icons.shopping_bag;
      case 'outerwear': return Icons.dry_cleaning;
      case 'dresses': return Icons.local_mall;
      case 'footwear': return Icons.directions_walk;
      case 'accessories': return Icons.watch;
      case 'bags': return Icons.work;
      default: return Icons.checkroom;
    }
  }

  Color _parseColor(String? colorName) {
    const map = {
      'black': Color(0xFF1A1A1A), 'white': Color(0xFFF5F5F5), 'navy': Color(0xFF1A237E),
      'gray': Color(0xFF757575), 'grey': Color(0xFF757575), 'beige': Color(0xFFD7C4A1),
      'brown': Color(0xFF6D4C41), 'red': Color(0xFFE53935), 'blue': Color(0xFF1E88E5),
      'green': Color(0xFF43A047), 'yellow': Color(0xFFFDD835), 'pink': Color(0xFFE91E63),
      'purple': Color(0xFF8E24AA), 'orange': Color(0xFFFB8C00), 'burgundy': Color(0xFF8E1A1A),
      'olive': Color(0xFF607D3A), 'cream': Color(0xFFFFF8E1),
    };
    return map[colorName?.toLowerCase()] ?? AppTheme.surfaceLight;
  }
}

// ─── Add/Edit Item Dialog ───────────────────────────

class AddEditItemDialog extends StatefulWidget {
  final WardrobeItem? item;
  final VoidCallback onSaved;

  const AddEditItemDialog({super.key, this.item, required this.onSaved});

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _priceCtrl;
  String _category = 'Tops';
  String? _colorPrimary;
  String? _pattern;
  String? _fabric;
  String? _formality;
  String _season = 'all_season';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _brandCtrl = TextEditingController(text: item?.brand ?? '');
    _priceCtrl = TextEditingController(text: item?.purchasePrice?.toStringAsFixed(0) ?? '');
    _category = item?.category ?? 'Tops';
    _colorPrimary = item?.colorPrimary;
    _pattern = item?.pattern;
    _fabric = item?.fabric;
    _formality = item?.formalityLevel;
    _season = item?.season ?? 'all_season';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'category': _category,
      if (_colorPrimary != null) 'color_primary': _colorPrimary,
      if (_pattern != null) 'pattern': _pattern,
      if (_fabric != null) 'fabric': _fabric,
      if (_formality != null) 'formality_level': _formality,
      'season': _season,
      if (_brandCtrl.text.isNotEmpty) 'brand': _brandCtrl.text.trim(),
      if (_priceCtrl.text.isNotEmpty) 'purchase_price': double.tryParse(_priceCtrl.text),
    };

    try {
      if (widget.item != null) {
        await ApiClient.updateWardrobeItem(widget.item!.id, data);
        if (mounted) showAppSnackBar(context, 'Item updated');
      } else {
        await ApiClient.createWardrobeItem(data);
        if (mounted) showAppSnackBar(context, 'Item added');
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to save', isError: true);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item != null ? 'Edit Item' : 'Add Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const ['Tops', 'Bottoms', 'Outerwear', 'Dresses', 'Footwear',
                  'Accessories', 'Bags', 'Suits', 'Knitwear']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _colorPrimary,
                decoration: const InputDecoration(labelText: 'Primary Color'),
                items: ClothingCategories.colors
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _colorPrimary = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _pattern,
                decoration: const InputDecoration(labelText: 'Pattern'),
                items: ClothingCategories.patterns
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _pattern = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _fabric,
                decoration: const InputDecoration(labelText: 'Fabric'),
                items: ClothingCategories.fabrics
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _fabric = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _formality,
                decoration: const InputDecoration(labelText: 'Formality'),
                items: ClothingCategories.formalityLevels
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _formality = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Purchase Price'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
