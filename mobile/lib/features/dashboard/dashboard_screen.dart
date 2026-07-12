/// Dashboard screen — overview: weather, stats, today's outfit, missing items, quick actions.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/outfit_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateWardrobe;
  final VoidCallback? onNavigateStylist;
  final VoidCallback? onNavigateChat;
  final VoidCallback? onNavigateShopping;
  final VoidCallback? onNavigateTryOn;
  final VoidCallback? onNavigateSubscription;

  const DashboardScreen({
    super.key,
    this.onNavigateWardrobe,
    this.onNavigateStylist,
    this.onNavigateChat,
    this.onNavigateShopping,
    this.onNavigateTryOn,
    this.onNavigateSubscription,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final json = await ApiClient.dashboardSummary();
      _summary = DashboardSummary.fromJson(json);
    } catch (e) {
      _error = 'Failed to load dashboard. Pull to retry.';
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Dashboard'),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.surfaceLight,
                    child: Text(
                      (ApiClient.userName?.isNotEmpty == true ? ApiClient.userName![0] : 'U').toUpperCase(),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(child: LoadingSpinner(message: 'Loading your style...'))
            else if (_error != null)
              SliverFillRemaining(child: ErrorDisplay(message: _error!, onRetry: _loadData))
            else if (_summary != null)
              _buildContent(context)
            else
              const SliverFillRemaining(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = _summary!;
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),

        // Weather widget
        if (s.weather != null) _buildWeatherCard(s.weather!),
        const SizedBox(height: 16),

        // Today's outfit
        if (s.todayOutfit != null && s.todayOutfit!.items.isNotEmpty)
          _buildTodayOutfitCard(s.todayOutfit!)
        else
          _buildEmptyOutfitCard(),
        const SizedBox(height: 16),

        // Stats grid
        _buildStatsGrid(s.wardrobeStats),
        const SizedBox(height: 16),

        // Subscription banner
        _buildSubscriptionBanner(s.subscriptionTier, s.tryonCredits),
        const SizedBox(height: 16),

        // Quick actions
        _buildQuickActions(),
        const SizedBox(height: 16),

        // Missing items
        if (s.missingItems.isNotEmpty) ...[
          SectionHeader(
            title: 'Missing Pieces',
            actionText: 'Shop',
            onAction: widget.onNavigateShopping,
          ),
          const SizedBox(height: 8),
          ...s.missingItems.map((m) => _buildMissingItemCard(m)),
          const SizedBox(height: 16),
        ],

        // Upcoming events
        if (s.upcomingEvents.isNotEmpty) ...[
          const SectionHeader(title: 'Upcoming Events'),
          const SizedBox(height: 8),
          ...s.upcomingEvents.map((e) => _buildEventCard(e)),
        ],

        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildWeatherCard(WeatherInfo w) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny, color: AppTheme.warning, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${w.temperatureC.round()}°C in ${w.city}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(w.conditionText, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (w.humidity != null)
            _buildWeatherDetail('${w.humidity}%', 'Humidity'),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildTodayOutfitCard(OutfitResponse outfit) {
    return GlassCard(
      onTap: widget.onNavigateStylist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Today's Outfit", style: Theme.of(context).textTheme.headlineSmall),
              ),
              if (outfit.aiConfidenceScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${(outfit.aiConfidenceScore! * 100).round()}% match',
                      style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (outfit.aiReasoning != null) ...[
            const SizedBox(height: 8),
            Text(outfit.aiReasoning!, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          // Outfit item chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: outfit.items.map((slot) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_roleIcon(slot.role), size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(slot.item.name, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'top': return Icons.checkroom;
      case 'bottom': return Icons.shopping_bag;
      case 'footwear': return Icons.directions_walk;
      case 'outerwear': return Icons.dry_cleaning;
      case 'accessory': return Icons.watch;
      default: return Icons.checkroom;
    }
  }

  Widget _buildEmptyOutfitCard() {
    return GlassCard(
      onTap: widget.onNavigateStylist,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Get Today's Outfit", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Let AI pick the perfect look from your wardrobe',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WardrobeStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildStatCard('Total Items', stats.totalItems.toString(), Icons.checkroom, AppTheme.primary),
        _buildStatCard('Favorites', stats.favoritesCount.toString(), Icons.favorite, AppTheme.accent),
        _buildStatCard('Categories', stats.byCategory.length.toString(), Icons.category, AppTheme.success),
        _buildStatCard('Recently Worn', stats.recentlyWornCount.toString(), Icons.history, AppTheme.warning),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner(String tier, int credits) {
    return GlassCard(
      onTap: widget.onNavigateSubscription,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tier[0].toUpperCase()}${tier.substring(1)} Plan',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('$credits try-on credits remaining',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildQuickActionCard('Wardrobe', Icons.checkroom_outlined, widget.onNavigateWardrobe)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickActionCard('Stylist', Icons.auto_awesome_outlined, widget.onNavigateStylist)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickActionCard('Try-On', Icons.face_retouching_natural_outlined, widget.onNavigateTryOn)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickActionCard('Shop', Icons.shopping_bag_outlined, widget.onNavigateShopping)),
      ],
    );
  }

  Widget _buildQuickActionCard(String label, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingItemCard(MissingPieceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: widget.onNavigateShopping,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(item.reason,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PriorityBadge(priority: item.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final date = DateTime.tryParse(event['event_date'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'] as String? ?? 'Event',
                      style: Theme.of(context).textTheme.bodyLarge),
                  if (date != null)
                    Text('${date.day}/${date.month}/${date.year}',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
