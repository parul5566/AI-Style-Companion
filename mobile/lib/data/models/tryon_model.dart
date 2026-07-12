/// Try-On model — matches backend TryOnResponse + TryOnHistoryItem.

class TryOnResponse {
  final int id;
  final String productName;
  final String? productCategory;
  final String? productImageUrl;
  final String? vendor;
  final String? resultImagePath;
  final int creditsUsed;
  final int creditsRemaining;
  final String status;
  final DateTime? createdAt;

  TryOnResponse({
    required this.id,
    required this.productName,
    this.productCategory,
    this.productImageUrl,
    this.vendor,
    this.resultImagePath,
    required this.creditsUsed,
    required this.creditsRemaining,
    this.status = 'completed',
    this.createdAt,
  });

  factory TryOnResponse.fromJson(Map<String, dynamic> json) {
    return TryOnResponse(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      vendor: json['vendor'] as String?,
      resultImagePath: json['result_image_path'] as String?,
      creditsUsed: json['credits_used'] as int? ?? 1,
      creditsRemaining: json['credits_remaining'] as int? ?? 0,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class TryOnHistoryItem {
  final int id;
  final String productName;
  final String? productImageUrl;
  final String? resultImagePath;
  final String status;
  final DateTime? createdAt;

  TryOnHistoryItem({
    required this.id,
    required this.productName,
    this.productImageUrl,
    this.resultImagePath,
    this.status = 'completed',
    this.createdAt,
  });

  factory TryOnHistoryItem.fromJson(Map<String, dynamic> json) {
    return TryOnHistoryItem(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      productImageUrl: json['product_image_url'] as String?,
      resultImagePath: json['result_image_path'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class AvatarInfo {
  final String avatarPhotoPath;

  AvatarInfo({required this.avatarPhotoPath});

  factory AvatarInfo.fromJson(Map<String, dynamic> json) {
    return AvatarInfo(
      avatarPhotoPath: json['avatar_photo_path'] as String,
    );
  }
}
