/// Subscription screen — view current plan + upgrade/downgrade tiers.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/subscription_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Subscription? _current;
  List<TierInfo> _tiers = [];
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
      final results = await Future.wait([
        ApiClient.getSubscription(),
        ApiClient.getTiers(),
      ]);
      _current = Subscription.fromJson(results[0] as Map<String, dynamic>);
      _tiers = (results[1] as List<dynamic>)
          .map((e) => TierInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load subscription info.';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectTier(String tier) async {
    if (tier == _current?.tier) return;

    setState(() => _isLoading = true);
    try {
      final json = await ApiClient.updateTier(tier);
      _current = Subscription.fromJson(json);
      if (mounted) showAppSnackBar(context, 'Switched to ${tier[0].toUpperCase()}${tier.substring(1)} plan!');
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to change plan', isError: true);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: _isLoading
          ? const LoadingSpinner()
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadData)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Current plan banner
                      if (_current != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Plan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${_current!.tier[0].toUpperCase()}${_current!.tier.substring(1)}',
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.style, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text('${_current!.tryonCreditsRemaining} / ${_current!.tryonCreditsMonthly} try-on credits',
                                      style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Tier cards
                      Text('Available Plans', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      ..._tiers.map((t) => _buildTierCard(t)),
                      const SizedBox(height: 32),

                      // Feature comparison note
                      GlassCard(
                        child: Column(
                          children: [
                            Icon(Icons.workspace_premium, color: AppTheme.primary.withOpacity(0.5), size: 32),
                            const SizedBox(height: 12),
                            Text('Upgrade anytime. Cancel whenever. No hidden fees.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTierCard(TierInfo tier) {
    final isCurrent = tier.name == _current?.tier;
    final tierColors = {
      'free': AppTheme.success,
      'basic': AppTheme.primary,
      'plus': AppTheme.accent,
      'premium': AppTheme.warning,
    };
    final color = tierColors[tier.name] ?? AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: isCurrent ? null : () => _selectTier(tier.name),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.diamond, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${tier.name[0].toUpperCase()}${tier.name.substring(1)}',
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text('${tier.creditsMonthly} credits/month',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(tier.priceLabel, style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color,
                )),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...tier.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                ],
              ),
            )),
            const SizedBox(height: 12),
            if (isCurrent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Current Plan', textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _selectTier(tier.name),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: const Text('Switch to this Plan'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
