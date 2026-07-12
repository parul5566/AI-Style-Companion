/// Outfit recommendation models — match backend OutfitResponse.
import 'wardrobe_model.dart';

class OutfitItemSlot {
  final String role;
  final WardrobeItem item;

  OutfitItemSlot({required this.role, required this.item});

  factory OutfitItemSlot.fromJson(Map<String, dynamic> json) {
    return OutfitItemSlot(
      role: json['role'] as String? ?? 'top',
      item: WardrobeItem.fromJson(json['item'] as Map<String, dynamic>),
    );
  }
}

class OutfitResponse {
  final int? id;
  final String name;
  final String? occasion;
  final String? weatherContext;
  final double? aiConfidenceScore;
  final bool isAiGenerated;
  final List<OutfitItemSlot> items;
  final String? aiReasoning;
  final DateTime? createdAt;

  OutfitResponse({
    this.id,
    required this.name,
    this.occasion,
    this.weatherContext,
    this.aiConfidenceScore,
    this.isAiGenerated = false,
    this.items = const [],
    this.aiReasoning,
    this.createdAt,
  });

  factory OutfitResponse.fromJson(Map<String, dynamic> json) {
    return OutfitResponse(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Outfit',
      occasion: json['occasion'] as String?,
      weatherContext: json['weather_context'] as String?,
      aiConfidenceScore: json['ai_confidence_score'] != null
          ? double.tryParse(json['ai_confidence_score'].toString())
          : null,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OutfitItemSlot.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      aiReasoning: json['ai_reasoning'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

// ===== Missing Pieces =====

class MissingPieceItem {
  final String category;
  final String name;
  final String reason;
  final String priority;
  final String? suggestedPriceRange;

  MissingPieceItem({
    required this.category,
    required this.name,
    required this.reason,
    required this.priority,
    this.suggestedPriceRange,
  });

  factory MissingPieceItem.fromJson(Map<String, dynamic> json) {
    return MissingPieceItem(
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      suggestedPriceRange: json['suggested_price_range'] as String?,
    );
  }
}

class MissingPieceResponse {
  final String eventType;
  final List<String> have;
  final List<MissingPieceItem> missing;
  final String? summary;

  MissingPieceResponse({
    required this.eventType,
    this.have = const [],
    this.missing = const [],
    this.summary,
  });

  factory MissingPieceResponse.fromJson(Map<String, dynamic> json) {
    return MissingPieceResponse(
      eventType: json['event_type'] as String? ?? '',
      have: (json['have'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      missing: (json['missing'] as List<dynamic>?)
          ?.map((e) => MissingPieceItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      summary: json['summary'] as String?,
    );
  }
}
