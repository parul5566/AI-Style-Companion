/// Dashboard models — match backend DashboardSummary.
import 'outfit_model.dart';

class WeatherInfo {
  final String city;
  final double temperatureC;
  final double? feelsLikeC;
  final String conditionText;
  final int? humidity;
  final double? windKph;

  WeatherInfo({
    required this.city,
    required this.temperatureC,
    this.feelsLikeC,
    required this.conditionText,
    this.humidity,
    this.windKph,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      city: json['city'] as String? ?? '',
      temperatureC: (json['temperature_c'] as num).toDouble(),
      feelsLikeC: json['feels_like_c'] != null
          ? (json['feels_like_c'] as num).toDouble()
          : null,
      conditionText: json['condition_text'] as String? ?? '',
      humidity: json['humidity'] as int?,
      windKph: json['wind_kph'] != null
          ? (json['wind_kph'] as num).toDouble()
          : null,
    );
  }
}

class WardrobeStats {
  final int totalItems;
  final Map<String, int> byCategory;
  final int favoritesCount;
  final int recentlyWornCount;

  WardrobeStats({
    required this.totalItems,
    required this.byCategory,
    required this.favoritesCount,
    required this.recentlyWornCount,
  });

  factory WardrobeStats.fromJson(Map<String, dynamic> json) {
    return WardrobeStats(
      totalItems: json['total_items'] as int? ?? 0,
      byCategory: Map<String, int>.from(json['by_category'] as Map? ?? {}),
      favoritesCount: json['favorites_count'] as int? ?? 0,
      recentlyWornCount: json['recently_worn_count'] as int? ?? 0,
    );
  }
}

class DashboardSummary {
  final WeatherInfo? weather;
  final OutfitResponse? todayOutfit;
  final WardrobeStats wardrobeStats;
  final List<MissingPieceItem> missingItems;
  final List<Map<String, dynamic>> upcomingEvents;
  final String subscriptionTier;
  final int tryonCredits;

  DashboardSummary({
    this.weather,
    this.todayOutfit,
    required this.wardrobeStats,
    this.missingItems = const [],
    this.upcomingEvents = const [],
    this.subscriptionTier = 'free',
    this.tryonCredits = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      weather: json['weather'] != null
          ? WeatherInfo.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
      todayOutfit: json['today_outfit'] != null
          ? OutfitResponse.fromJson(json['today_outfit'] as Map<String, dynamic>)
          : null,
      wardrobeStats: WardrobeStats.fromJson(
          json['wardrobe_stats'] as Map<String, dynamic>),
      missingItems: (json['missing_items'] as List<dynamic>?)
          ?.map((e) => MissingPieceItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      upcomingEvents: (json['upcoming_events'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
          [],
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      tryonCredits: json['tryon_credits'] as int? ?? 0,
    );
  }
}
