/// API client using Dio with JWT interceptor and auto-logout on 401.
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config.dart';

class ApiClient {
  static late Dio _dio;
  static SharedPreferences? _prefs;

  /// Initialize the API client — call once at app startup.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Request interceptor — attach JWT token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _prefs?.getString(AppConfig.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Auto-clear token on 401
        if (error.response?.statusCode == 401) {
          _prefs?.remove(AppConfig.tokenKey);
          _prefs?.remove(AppConfig.userIdKey);
          _prefs?.remove(AppConfig.userEmailKey);
          _prefs?.remove(AppConfig.userNameKey);
        }
        handler.next(error);
      },
    ));
  }

  static Dio get dio => _dio;

  // ─── Auth ────────────────────────────────────────
  static Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    _saveAuth(res.data);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    _saveAuth(res.data);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  // ─── Profile ─────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/profile');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/profile', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ─── Wardrobe ────────────────────────────────────
  static Future<List<dynamic>> listWardrobeItems({
    String? category,
    bool? isFavorite,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (isFavorite != null) params['is_favorite'] = isFavorite;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _dio.get('/wardrobe/items', queryParameters: params);
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createWardrobeItem(Map<String, dynamic> data) async {
    final res = await _dio.post('/wardrobe/items', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateWardrobeItem(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/wardrobe/items/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<void> deleteWardrobeItem(int id) async {
    await _dio.delete('/wardrobe/items/$id');
  }

  static Future<Map<String, dynamic>> uploadWardrobeItem(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/wardrobe/items/upload', data: formData);
    return res.data as Map<String, dynamic>;
  }

  // ─── Outfits ─────────────────────────────────────
  static Future<Map<String, dynamic>> recommendOutfit(Map<String, dynamic> data) async {
    final res = await _dio.post('/outfits/recommend', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> outfitHistory() async {
    final res = await _dio.get('/outfits/history');
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> outfitFeedback(int outfitId, String feedback) async {
    final res = await _dio.post('/outfits/$outfitId/feedback', data: {'feedback': feedback});
    return res.data as Map<String, dynamic>;
  }

  // ─── AI ──────────────────────────────────────────
  static Future<Map<String, dynamic>> aiTag(String description) async {
    final res = await _dio.post('/ai/tag', queryParameters: {'description': description});
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> missingPieces(Map<String, dynamic> data) async {
    final res = await _dio.post('/ai/missing-pieces', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ─── Chat ────────────────────────────────────────
  static Future<Map<String, dynamic>> sendChatMessage(Map<String, dynamic> data) async {
    final res = await _dio.post('/chat/message', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getConversations() async {
    final res = await _dio.get('/chat/conversations');
    return res.data as List<dynamic>;
  }

  // ─── Dashboard ───────────────────────────────────
  static Future<Map<String, dynamic>> dashboardSummary({String? city}) async {
    final res = await _dio.get('/dashboard/summary', queryParameters: {
      if (city != null) 'city': city,
    });
    return res.data as Map<String, dynamic>;
  }

  // ─── Weather ─────────────────────────────────────
  static Future<Map<String, dynamic>> getWeather(String city) async {
    final res = await _dio.get('/weather', queryParameters: {'city': city});
    return res.data as Map<String, dynamic>;
  }

  // ─── Subscriptions ───────────────────────────────
  static Future<Map<String, dynamic>> getSubscription() async {
    final res = await _dio.get('/subscriptions');
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getTiers() async {
    final res = await _dio.get('/subscriptions/tiers');
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> updateTier(String tier) async {
    final res = await _dio.put('/subscriptions/tier', data: {'tier': tier});
    return res.data as Map<String, dynamic>;
  }

  // ─── Events ──────────────────────────────────────
  static Future<List<dynamic>> listEvents() async {
    final res = await _dio.get('/events');
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    final res = await _dio.post('/events', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<void> deleteEvent(int id) async {
    await _dio.delete('/events/$id');
  }

  // ─── Wardrobe Wear ───────────────────────────────
  static Future<Map<String, dynamic>> markItemWorn(int itemId) async {
    final res = await _dio.post('/wardrobe/items/$itemId/wear');
    return res.data as Map<String, dynamic>;
  }

  // ─── Outfit Alternative ──────────────────────────
  static Future<Map<String, dynamic>> recommendAlternative(Map<String, dynamic> data) async {
    final res = await _dio.post('/outfits/recommend/alternative', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ─── Shopping ────────────────────────────────────
  static Future<List<dynamic>> listProducts({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    final res = await _dio.get('/shopping/products', queryParameters: params);
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getProduct(int productId) async {
    final res = await _dio.get('/shopping/products/$productId');
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> productsByCategory(String category, {int limit = 5}) async {
    final res = await _dio.get('/shopping/products/by-category/$category', queryParameters: {'limit': limit});
    return res.data as List<dynamic>;
  }

  static Future<List<dynamic>> getShoppingCategories() async {
    final res = await _dio.get('/shopping/categories');
    return res.data as List<dynamic>;
  }

  static Future<List<dynamic>> getWishlist() async {
    final res = await _dio.get('/shopping/wishlist');
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> addToWishlist(int productId) async {
    final res = await _dio.post('/shopping/wishlist/$productId');
    return res.data as Map<String, dynamic>;
  }

  static Future<void> removeFromWishlist(int productId) async {
    await _dio.delete('/shopping/wishlist/$productId');
  }

  // ─── Try-On ──────────────────────────────────────
  static Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/tryon/avatar', data: formData);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAvatar() async {
    final res = await _dio.get('/tryon/avatar');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> renderTryOn(Map<String, dynamic> data) async {
    final res = await _dio.post('/tryon/render', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> tryOnHistory() async {
    final res = await _dio.get('/tryon/history');
    return res.data as List<dynamic>;
  }

  // ─── Helpers ─────────────────────────────────────
  static void _saveAuth(Map<String, dynamic> data) {
    _prefs?.setString(AppConfig.tokenKey, data['access_token'] as String);
    _prefs?.setInt(AppConfig.userIdKey, data['user_id'] as int);
    _prefs?.setString(AppConfig.userEmailKey, data['email'] as String);
    _prefs?.setString(AppConfig.userNameKey, data['full_name'] as String);
  }

  static Future<void> logout() async {
    await _prefs?.remove(AppConfig.tokenKey);
    await _prefs?.remove(AppConfig.userIdKey);
    await _prefs?.remove(AppConfig.userEmailKey);
    await _prefs?.remove(AppConfig.userNameKey);
  }

  static bool get isLoggedIn =>
      _prefs?.getString(AppConfig.tokenKey) != null;

  static String? get token => _prefs?.getString(AppConfig.tokenKey);
  static String? get userEmail => _prefs?.getString(AppConfig.userEmailKey);
  static String? get userName => _prefs?.getString(AppConfig.userNameKey);
  static int? get userId => _prefs?.getInt(AppConfig.userIdKey);
}
