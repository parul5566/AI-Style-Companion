/// Auth provider — manages login/register/logout state.
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  UserProfile? _profile;
  String? _email;
  String? _fullName;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  UserProfile? get profile => _profile;
  String? get email => _email;
  String? get fullName => _fullName;

  bool get needsOnboarding => _profile == null || !_profile!.onboardingCompleted;

  /// Check persisted auth state on startup.
  Future<void> checkAuth() async {
    if (ApiClient.isLoggedIn) {
      _isLoggedIn = true;
      _email = ApiClient.userEmail;
      _fullName = ApiClient.userName;
      try {
        final profileJson = await ApiClient.getProfile();
        _profile = UserProfile.fromJson(profileJson);
      } catch (_) {
        // Profile might not exist yet — that's OK
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiClient.login(email, password);
      _isLoggedIn = true;
      _email = data['email'] as String;
      _fullName = data['full_name'] as String;

      // Fetch profile
      try {
        final profileJson = await ApiClient.getProfile();
        _profile = UserProfile.fromJson(profileJson);
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is Exception) {
        final msg = e.toString();
        _errorMessage = msg.contains('401')
            ? 'Invalid email or password'
            : msg.contains('404')
                ? 'Account not found'
                : 'Login failed. Check your connection.';
      } else {
        _errorMessage = 'Login failed. Check your connection.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiClient.register(email, password, fullName);
      _isLoggedIn = true;
      _email = data['email'] as String;
      _fullName = data['full_name'] as String;
      _profile = null; // new user — no profile yet
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is Exception) {
        final msg = e.toString();
        _errorMessage = msg.contains('409')
            ? 'Email already registered. Try logging in.'
            : 'Registration failed. Please try again.';
      } else {
        _errorMessage = 'Registration failed. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOnboarding(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      profileData['onboarding_completed'] = true;
      final json = await ApiClient.updateProfile(profileData);
      _profile = UserProfile.fromJson(json);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to save profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    _isLoggedIn = false;
    _profile = null;
    _email = null;
    _fullName = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
