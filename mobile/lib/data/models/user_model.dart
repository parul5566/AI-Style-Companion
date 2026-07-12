// ===== Auth Models =====

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String email;
  final String fullName;

  TokenResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.userId,
    required this.email,
    required this.fullName,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      userId: json['user_id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
    );
  }
}

class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ===== Profile Model =====

class UserProfile {
  final int? id;
  final int userId;
  final String? gender;
  final String? ageRange;
  final int? budgetMin;
  final int? budgetMax;
  final List<String>? preferredColors;
  final List<String>? avoidedColors;
  final List<String>? stylePreferences;
  final List<String>? favoriteOccasions;
  final String? bodyType;
  final bool onboardingCompleted;
  final DateTime? createdAt;

  UserProfile({
    this.id,
    required this.userId,
    this.gender,
    this.ageRange,
    this.budgetMin,
    this.budgetMax,
    this.preferredColors,
    this.avoidedColors,
    this.stylePreferences,
    this.favoriteOccasions,
    this.bodyType,
    required this.onboardingCompleted,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      gender: json['gender'] as String?,
      ageRange: json['age_range'] as String?,
      budgetMin: json['budget_min'] as int?,
      budgetMax: json['budget_max'] as int?,
      preferredColors: (json['preferred_colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      avoidedColors: (json['avoided_colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      stylePreferences: (json['style_preferences'] as List<dynamic>?)?.map((e) => e as String).toList(),
      favoriteOccasions: (json['favorite_occasions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      bodyType: json['body_type'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (gender != null) 'gender': gender,
      if (ageRange != null) 'age_range': ageRange,
      if (budgetMin != null) 'budget_min': budgetMin,
      if (budgetMax != null) 'budget_max': budgetMax,
      if (preferredColors != null) 'preferred_colors': preferredColors,
      if (avoidedColors != null) 'avoided_colors': avoidedColors,
      if (stylePreferences != null) 'style_preferences': stylePreferences,
      if (favoriteOccasions != null) 'favorite_occasions': favoriteOccasions,
      if (bodyType != null) 'body_type': bodyType,
      if (id != null) 'onboarding_completed': onboardingCompleted,
    };
  }
}
