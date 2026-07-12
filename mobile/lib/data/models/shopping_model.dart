/// Shopping product model — matches backend ShoppingProductResponse.
import 'dart:core';

class ShoppingProduct {
  final int id;
  final String name;
  final String category;
  final String? brand;
  final double price;
  final String currency;
  final String? imageUrl;
  final String productUrl;
  final String vendor;
  final Map<String, dynamic>? tags;

  ShoppingProduct({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    required this.price,
    this.currency = 'USD',
    this.imageUrl,
    this.productUrl = '#',
    required this.vendor,
    this.tags,
  });

  factory ShoppingProduct.fromJson(Map<String, dynamic> json) {
    return ShoppingProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: json['image_url'] as String?,
      productUrl: json['product_url'] as String? ?? '#',
      vendor: json['vendor'] as String? ?? '',
      tags: json['tags'] as Map<String, dynamic>?,
    );
  }
}

class WishlistItem {
  final int id;
  final ShoppingProduct product;

  WishlistItem({required this.id, required this.product});

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as int,
      product: ShoppingProduct.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}

class ShoppingCategory {
  final String category;
  final int count;

  ShoppingCategory({required this.category, required this.count});

  factory ShoppingCategory.fromJson(Map<String, dynamic> json) {
    return ShoppingCategory(
      category: json['category'] as String,
      count: json['count'] as int,
    );
  }
}
