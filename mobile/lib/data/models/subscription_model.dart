/// Subscription models — match backend SubscriptionResponse + TierInfo.

class Subscription {
  final int id;
  final int userId;
  final String tier;
  final int tryonCreditsRemaining;
  final int tryonCreditsMonthly;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? renewsAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.tryonCreditsRemaining,
    required this.tryonCreditsMonthly,
    required this.isActive,
    required this.startedAt,
    this.renewsAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      tier: json['tier'] as String? ?? 'free',
      tryonCreditsRemaining: json['tryon_credits_remaining'] as int? ?? 0,
      tryonCreditsMonthly: json['tryon_credits_monthly'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startedAt: DateTime.parse(json['started_at'] as String),
      renewsAt: json['renews_at'] != null
          ? DateTime.tryParse(json['renews_at'] as String)
          : null,
    );
  }
}

class TierInfo {
  final String name;
  final int creditsMonthly;
  final List<String> features;
  final String priceLabel;

  TierInfo({
    required this.name,
    required this.creditsMonthly,
    required this.features,
    required this.priceLabel,
  });

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    return TierInfo(
      name: json['name'] as String,
      creditsMonthly: json['credits_monthly'] as int? ?? 0,
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      priceLabel: json['price_label'] as String? ?? '',
    );
  }
}
