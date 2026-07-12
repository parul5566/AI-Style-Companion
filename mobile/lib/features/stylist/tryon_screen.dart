/// Try-On Studio screen — avatar upload + virtual try-on with credit gating.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models/shopping_model.dart';
import '../../data/models/tryon_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  String? _avatarPath;
  bool _hasAvatar = false;
  int _credits = 0;
  List<TryOnHistoryItem> _history = [];
  List<ShoppingProduct> _products = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load avatar, credits, history, and products in parallel
      final results = await Future.wait([
        _loadAvatar(),
        ApiClient.getSubscription(),
        ApiClient.tryOnHistory(),
        ApiClient.listProducts(limit: 20),
      ]);

      _hasAvatar = results[0] as bool;
      _credits = (results[1] as Map<String, dynamic>)['tryon_credits_remaining'] as int? ?? 0;
      _history = (results[2] as List<dynamic>)
          .map((e) => TryOnHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _products = (results[3] as List<dynamic>)
          .map((e) => ShoppingProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<bool> _loadAvatar() async {
    try {
      final json = await ApiClient.getAvatar();
      _avatarPath = json['avatar_photo_path'] as String?;
      return _avatarPath != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (photo == null) return;

      setState(() => _isProcessing = true);
      final json = await ApiClient.uploadAvatar(photo.path);
      _avatarPath = json['avatar_photo_path'] as String?;
      setState(() {
        _hasAvatar = true;
        _isProcessing = false;
      });
      if (mounted) showAppSnackBar(context, 'Avatar uploaded!');
    } catch (_) {
      setState(() => _isProcessing = false);
      if (mounted) showAppSnackBar(context, 'Upload failed', isError: true);
    }
  }

  Future<void> _tryOnProduct(ShoppingProduct product) async {
    if (_credits <= 0) {
      showAppSnackBar(context, 'No credits remaining! Upgrade your plan.', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final json = await ApiClient.renderTryOn({
        'product_name': product.name,
        'product_category': product.category,
        'product_image_url': product.imageUrl,
        'vendor': product.vendor,
      });
      final result = TryOnResponse.fromJson(json);
      _credits = result.creditsRemaining;

      // Add to history
      setState(() {
        _history.insert(0, TryOnHistoryItem(
          id: result.id,
          productName: result.productName,
          productImageUrl: result.productImageUrl,
          resultImagePath: result.resultImagePath,
          status: result.status,
          createdAt: result.createdAt,
        ));
        _isProcessing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Try-On Complete!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.resultImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(result.resultImagePath!, height: 200, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.image_not_supported, size: 48, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('${result.creditsRemaining} credits remaining',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) showAppSnackBar(context, 'Try-on failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On Studio')),
      body: _isLoading
          ? const LoadingSpinner()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Credit banner
                    _buildCreditBanner(),
                    const SizedBox(height: 16),

                    // Avatar section
                    _buildAvatarSection(),
                    const SizedBox(height: 24),

                    // Try-on products
                    if (_hasAvatar) ...[
                      const SectionHeader(title: 'Try On Products'),
                      const SizedBox(height: 8),
                      if (_products.isEmpty)
                        const EmptyState(title: 'No products available')
                      else
                        ..._products.take(6).map((p) => _buildProductCard(p)),
                    ],

                    // History
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Recent Try-Ons'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _history.length,
                          itemBuilder: (ctx, i) => _buildHistoryItem(_history[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCreditBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.style, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_credits Try-On Credits',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('Remaining this month',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (_credits == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('UPGRADE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return GlassCard(
      child: Column(
        children: [
          if (_hasAvatar && _avatarPath != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: Image.network(
                  AppConfig.baseUrl.replaceAll('/api', '') + _avatarPath!,
                  width: 120, height: 120, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120, height: 120,
                    color: AppTheme.surfaceLight,
                    child: const Icon(Icons.person, size: 48, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Icon(Icons.person_outline, size: 48, color: AppTheme.textSecondary),
            ),
          const SizedBox(height: 16),
          Text(
            _hasAvatar ? 'Your Avatar' : 'Upload Your Avatar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _hasAvatar
                ? 'Tap products below to try them on your avatar'
                : 'Upload a full-body photo to start trying on looks virtually',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _uploadAvatar,
            icon: const Icon(Icons.upload),
            label: Text(_hasAvatar ? 'Change Avatar' : 'Upload Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ShoppingProduct product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64, height: 64,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.shopping_bag, color: AppTheme.textSecondary),
                      ),
                    )
                  : Container(
                      width: 64, height: 64,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.shopping_bag, color: AppTheme.textSecondary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${product.brand ?? product.vendor} • \$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isProcessing || _credits == 0
                  ? null
                  : () => _tryOnProduct(product),
              child: const Text('Try On'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(TryOnHistoryItem item) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (item.resultImagePath ?? item.productImageUrl) != null
                    ? Image.network(item.resultImagePath ?? item.productImageUrl!,
                        fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.checkroom, color: AppTheme.textSecondary),
                        ),
                      )
                    : Container(
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.checkroom, color: AppTheme.textSecondary),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
