/// Shopping screen — browse vendor products, filter, wishlist.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/shopping_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  List<ShoppingProduct> _products = [];
  Set<int> _wishlistIds = {};
  bool _isLoading = true;
  String? _error;
  String? _activeCategory;
  final _searchCtrl = TextEditingController();

  final _categories = [
    'Tops', 'Bottoms', 'Outerwear', 'Dresses', 'Footwear',
    'Accessories', 'Bags',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiClient.listProducts(
          category: _activeCategory,
          search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
        ),
        ApiClient.getWishlist(),
      ]);
      _products = (results[0] as List<dynamic>)
          .map((e) => ShoppingProduct.fromJson(e as Map<String, dynamic>))
          .toList();
      _wishlistIds = (results[1] as List<dynamic>)
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>).product.id)
          .toSet();
    } catch (_) {
      _error = 'Failed to load products.';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleWishlist(ShoppingProduct product) async {
    final isWishlisted = _wishlistIds.contains(product.id);
    try {
      if (isWishlisted) {
        await ApiClient.removeFromWishlist(product.id);
        setState(() => _wishlistIds.remove(product.id));
      } else {
        await ApiClient.addToWishlist(product.id);
        setState(() => _wishlistIds.add(product.id));
        if (mounted) showAppSnackBar(context, 'Added to wishlist');
      }
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Failed to update wishlist', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () { _searchCtrl.clear(); _loadData(); },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadData(),
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
                    setState(() => _activeCategory = null);
                    _loadData();
                  });
                }
                final cat = _categories[i - 1];
                final isActive = _activeCategory == cat;
                return _filterChip(cat, isActive, () {
                  setState(() => _activeCategory = isActive ? null : cat);
                  _loadData();
                });
              },
            ),
          ),

          const SizedBox(height: 4),

          // Products
          Expanded(
            child: _isLoading
                ? const LoadingSpinner()
                : _error != null
                    ? ErrorDisplay(message: _error!, onRetry: _loadData)
                    : _products.isEmpty
                        ? const EmptyState(
                            title: 'No Products Found',
                            subtitle: 'Try different filters or search terms.',
                            icon: Icons.shopping_bag_outlined,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
                          ),
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

  Widget _buildProductCard(ShoppingProduct product) {
    final isWishlisted = _wishlistIds.contains(product.id);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, size: 40, color: AppTheme.textSecondary),
                          ),
                        )
                      : const Icon(Icons.shopping_bag, size: 40, color: AppTheme.textSecondary),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(product),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.background.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isWishlisted ? AppTheme.accent : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(product.brand ?? product.vendor,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(product.category,
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
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
}
