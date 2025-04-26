import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        // Set token in API service
        _apiService.token = token;

        // Here you would normally validate the token or get user details
        // For now, we'll just get the stored user data
        final userData = await _storage.read(key: 'userData');
        if (userData != null) {
          _user = User.fromStorage(userData);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to restore session';
      await logout(); // Clear any invalid session data
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _apiService.login(email, password);
      _user = user;

      // Store tokens securely
      await _storage.write(key: 'accessToken', value: user.token);
      await _storage.write(key: 'userData', value: user.toStorage());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Login failed. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String role,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _apiService.register(username, email, password, role);
      _user = user;

      // Store tokens securely
      await _storage.write(key: 'accessToken', value: user.token);
      await _storage.write(key: 'userData', value: user.toStorage());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Registration failed. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'userData');
    _apiService.token = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
