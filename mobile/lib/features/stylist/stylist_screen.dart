/// AI Stylist screen — outfit recommendations + missing piece analysis.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/outfit_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key});

  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Stylist'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checkroom), text: 'Outfits'),
            Tab(icon: Icon(Icons.search), text: 'Missing Pieces'),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OutfitRecommendationTab(),
          MissingPiecesTab(),
        ],
      ),
    );
  }
}

// ─── Outfit Recommendation Tab ──────────────────────

class OutfitRecommendationTab extends StatefulWidget {
  const OutfitRecommendationTab({super.key});

  @override
  State<OutfitRecommendationTab> createState() => _OutfitRecommendationTabState();
}

class _OutfitRecommendationTabState extends State<OutfitRecommendationTab> {
  OutfitResponse? _outfit;
  bool _isLoading = false;
  String? _error;
  String _occasion = 'casual';
  String _city = 'London';

  static const _occasions = [
    'casual', 'work', 'date', 'interview', 'wedding',
    'party', 'travel', 'gym', 'formal',
  ];

  Future<void> _recommend() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final json = await ApiClient.recommendOutfit({
        'occasion': _occasion,
        'city': _city,
      });
      _outfit = OutfitResponse.fromJson(json);
    } catch (e) {
      _error = 'Failed to generate recommendation. Try again.';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _feedback(String feedback) async {
    if (_outfit?.id == null) return;
    try {
      await ApiClient.outfitFeedback(_outfit!.id!, feedback);
      if (feedback == 'rejected') {
        // Auto-generate alternative on reject
        await _generateAlternative();
      } else {
        if (mounted) showAppSnackBar(context, feedback == 'accepted'
            ? 'Great choice! Saved to your looks.'
            : 'Noted.');
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to submit feedback', isError: true);
    }
  }

  Future<void> _generateAlternative() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final json = await ApiClient.recommendAlternative({
        'occasion': _occasion,
        'city': _city,
      });
      _outfit = OutfitResponse.fromJson(json);
      if (mounted) showAppSnackBar(context, 'Here\'s a different look!');
    } catch (e) {
      _error = 'Failed to generate alternative. Try again.';
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Occasion selector
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What\'s the occasion?', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _occasion,
                  decoration: const InputDecoration(labelText: 'Occasion'),
                  items: _occasions.map((o) =>
                    DropdownMenuItem(value: o, child: Text(o[0].toUpperCase() + o.substring(1)))).toList(),
                  onChanged: (v) => setState(() => _occasion = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _city,
                  decoration: const InputDecoration(labelText: 'City (for weather)'),
                  onChanged: (v) => _city = v,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _recommend,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Outfit'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result
          if (_isLoading)
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: LoadingSpinner(message: 'Styling your perfect outfit...'),
              ),
            )
          else if (_error != null)
            ErrorDisplay(message: _error!, onRetry: _recommend)
          else if (_outfit != null)
            _buildOutfitResult(_outfit!)
          else
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome, size: 48, color: AppTheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('Tap "Generate Outfit" to get your AI-curated look.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutfitResult(OutfitResponse outfit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(outfit.name,
                        style: Theme.of(context).textTheme.headlineSmall),
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
              if (outfit.weatherContext != null) ...[
                const SizedBox(height: 8),
                Text('Weather: ${outfit.weatherContext}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (outfit.aiReasoning != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(outfit.aiReasoning!,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Outfit items
        if (outfit.items.isNotEmpty)
          ...outfit.items.map((slot) => _buildOutfitItemCard(slot)),
        const SizedBox(height: 16),

        // Feedback buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _feedback('accepted'),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Love it'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _feedback('maybe'),
                icon: const Icon(Icons.thumbs_up_down, size: 18),
                label: const Text('Maybe'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _feedback('rejected'),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Nope'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutfitItemCard(OutfitItemSlot slot) {
    final item = slot.item;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.checkroom, color: AppTheme.primary.withOpacity(0.7), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(slot.role.toUpperCase(),
                            style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${item.category}${item.brand != null ? ' • ${item.brand}' : ''}',
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

// ─── Missing Pieces Tab ────────────────────────────

class MissingPiecesTab extends StatefulWidget {
  const MissingPiecesTab({super.key});

  @override
  State<MissingPiecesTab> createState() => _MissingPiecesTabState();
}

class _MissingPiecesTabState extends State<MissingPiecesTab> {
  MissingPieceResponse? _result;
  bool _isLoading = false;
  String? _error;
  String _eventType = 'wedding';
  String? _dressCode;
  final _budgetCtrl = TextEditingController();

  static const _eventTypes = [
    'wedding', 'interview', 'date', 'work', 'party',
    'vacation', 'formal dinner', 'brunch', 'everyday casual',
  ];
  static const _dressCodes = [
    'casual', 'smart_casual', 'business', 'formal', 'black_tie',
  ];

  Future<void> _analyze() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final json = await ApiClient.missingPieces({
        'event_type': _eventType,
        if (_dressCode != null) 'dress_code': _dressCode,
        if (_budgetCtrl.text.isNotEmpty) 'budget_max': int.tryParse(_budgetCtrl.text),
      });
      _result = MissingPieceResponse.fromJson(json);
    } catch (e) {
      _error = 'Failed to analyze wardrobe. Try again.';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyze Your Wardrobe', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('Find gaps for specific events.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _eventType,
                  decoration: const InputDecoration(labelText: 'Event Type'),
                  items: _eventTypes.map((e) =>
                    DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
                  onChanged: (v) => setState(() => _eventType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _dressCode,
                  decoration: const InputDecoration(labelText: 'Dress Code (optional)'),
                  items: _dressCodes.map((d) =>
                    DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _dressCode = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Budget (optional)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _analyze,
                    icon: const Icon(Icons.search),
                    label: const Text('Analyze'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: LoadingSpinner(message: 'Analyzing your wardrobe...'),
              ),
            )
          else if (_error != null)
            ErrorDisplay(message: _error!, onRetry: _analyze)
          else if (_result != null)
            _buildResult(_result!)
          else
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.search, size: 48, color: AppTheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('Set your event details and tap "Analyze" to see what\'s missing from your wardrobe.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(MissingPieceResponse result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.summary != null)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result.summary!,
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // What you have
        if (result.have.isNotEmpty) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    const SizedBox(width: 8),
                    Text('What You Have', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: result.have.map((h) => Chip(
                    label: Text(h),
                    backgroundColor: AppTheme.success.withOpacity(0.15),
                    side: BorderSide.none,
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Missing pieces
        const SectionHeader(title: 'Missing Pieces'),
        const SizedBox(height: 8),
        ...result.missing.map((m) => _buildMissingCard(m)),
      ],
    );
  }

  Widget _buildMissingCard(MissingPieceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                ),
                PriorityBadge(priority: item.priority),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.reason, style: Theme.of(context).textTheme.bodyMedium),
            if (item.suggestedPriceRange != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Budget: ${item.suggestedPriceRange}',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
