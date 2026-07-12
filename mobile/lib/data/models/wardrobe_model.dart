/// Wardrobe item model — matches backend WardrobeItemResponse exactly.
class WardrobeItem {
  final int id;
  final int userId;
  final String name;
  final String category;
  final String? subcategory;
  final String? colorPrimary;
  final String? colorSecondary;
  final String? pattern;
  final String? fabric;
  final String? brand;
  final String? formalityLevel;
  final String? season;
  final String? imagePath;
  final Map<String, dynamic>? aiTags;
  final bool isFavorite;
  final int timesWorn;
  final DateTime? lastWornDate;
  final double? purchasePrice;
  final DateTime createdAt;

  WardrobeItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.subcategory,
    this.colorPrimary,
    this.colorSecondary,
    this.pattern,
    this.fabric,
    this.brand,
    this.formalityLevel,
    this.season,
    this.imagePath,
    this.aiTags,
    required this.isFavorite,
    required this.timesWorn,
    this.lastWornDate,
    this.purchasePrice,
    required this.createdAt,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      colorPrimary: json['color_primary'] as String?,
      colorSecondary: json['color_secondary'] as String?,
      pattern: json['pattern'] as String?,
      fabric: json['fabric'] as String?,
      brand: json['brand'] as String?,
      formalityLevel: json['formality_level'] as String?,
      season: json['season'] as String?,
      imagePath: json['image_path'] as String?,
      aiTags: json['ai_tags'] as Map<String, dynamic>?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      timesWorn: json['times_worn'] as int? ?? 0,
      lastWornDate: json['last_worn_date'] != null
          ? DateTime.tryParse(json['last_worn_date'] as String)
          : null,
      purchasePrice: json['purchase_price'] != null
          ? double.tryParse(json['purchase_price'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (colorPrimary != null) 'color_primary': colorPrimary,
      if (colorSecondary != null) 'color_secondary': colorSecondary,
      if (pattern != null) 'pattern': pattern,
      if (fabric != null) 'fabric': fabric,
      if (brand != null) 'brand': brand,
      if (formalityLevel != null) 'formality_level': formalityLevel,
      if (season != null) 'season': season,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
    };
  }
}

/// AI tag result — used when uploading a garment for AI analysis.
class AITagResult {
  final String name;
  final String category;
  final String? subcategory;
  final String? colorPrimary;
  final String? colorSecondary;
  final String? pattern;
  final String? fabric;
  final String? brand;
  final String? formalityLevel;
  final String? season;
  final String? description;
  final String? imagePath;

  AITagResult({
    required this.name,
    required this.category,
    this.subcategory,
    this.colorPrimary,
    this.colorSecondary,
    this.pattern,
    this.fabric,
    this.brand,
    this.formalityLevel,
    this.season,
    this.description,
    this.imagePath,
  });

  factory AITagResult.fromJson(Map<String, dynamic> json) {
    return AITagResult(
      name: json['name'] as String? ?? 'Unknown Item',
      category: json['category'] as String? ?? 'other',
      subcategory: json['subcategory'] as String?,
      colorPrimary: json['color_primary'] as String?,
      colorSecondary: json['color_secondary'] as String?,
      pattern: json['pattern'] as String?,
      fabric: json['fabric'] as String?,
      brand: json['brand'] as String?,
      formalityLevel: json['formality_level'] as String?,
      season: json['season'] as String?,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }
}

/// Clothing categories for filtering / selection.
class ClothingCategories {
  static const List<String> all = [
    'Tops', 'Bottoms', 'Outerwear', 'Dresses', 'Footwear',
    'Accessories', 'Bags', 'Jewelry', 'Activewear', 'Underwear',
    'Swimwear', 'Sleepwear', 'Suits', 'Knitwear',
  ];

  static const List<String> colors = [
    'Black', 'White', 'Navy', 'Gray', 'Beige', 'Brown',
    'Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Purple',
    'Orange', 'Burgundy', 'Olive', 'Cream', 'Tan', 'Multi',
  ];

  static const List<String> patterns = [
    'Solid', 'Striped', 'Plaid', 'Floral', 'Geometric',
    'Polka Dot', 'Animal Print', 'Color Block', 'Camouflage',
  ];

  static const List<String> fabrics = [
    'Cotton', 'Wool', 'Silk', 'Linen', 'Denim', 'Leather',
    'Synthetic', 'Cashmere', 'Polyester', 'Blend', 'Knit',
  ];

  static const List<String> formalityLevels = [
    'casual', 'smart_casual', 'business', 'formal', 'black_tie',
  ];

  static const List<String> seasons = [
    'spring', 'summer', 'fall', 'winter', 'all_season',
  ];
}
