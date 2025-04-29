import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/utils/logger.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;
  String? _refreshToken;

  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  AuthProvider({ApiService? apiService, FlutterSecureStorage? storage})
    : _apiService = apiService ?? ApiService(),
      _storage = storage ?? const FlutterSecureStorage() {
    _restoreSession();
  }

  // — Public getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // — Clear only the error message
  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  // — Load tokens & user from secure storage and push into ApiService
  Future<void> _restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedAccess = await _storage.read(key: 'accessToken');
      final storedRefresh = await _storage.read(key: 'refreshToken');
      final userData = await _storage.read(key: 'userData');

      print('Stored Access Token: $storedAccess');
      print('Stored Refresh Token: $storedRefresh');

      if (storedAccess != null && storedRefresh != null && userData != null) {
        _accessToken = storedAccess;
        _refreshToken = storedRefresh;
        _apiService.accessToken = storedAccess;
        _apiService.refreshToken = storedRefresh;
        _user = User.fromStorage(userData);
      }
    } catch (_) {
      _errorMessage = 'Failed to restore session';
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // — Login and persist session
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _apiService.login(email, password);

      _user = user;
      _accessToken = user.accessToken;
      _refreshToken = user.refreshToken;

      _apiService.accessToken = _accessToken;
      _apiService.refreshToken = _refreshToken;

      AppLogger.i("ApiService accessToken: ${_apiService.accessToken}");
      AppLogger.i("ApiService refreshToken: ${_apiService.refreshToken}");

      await _storage.write(key: 'accessToken', value: _accessToken);
      await _storage.write(key: 'refreshToken', value: _refreshToken);
      await _storage.write(key: 'userData', value: user.toStorage());
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // — Register and persist session
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
      _accessToken = user.accessToken;
      _refreshToken = user.refreshToken;

      _apiService.accessToken = _accessToken;
      _apiService.refreshToken = _refreshToken;

      await _storage.write(key: 'accessToken', value: _accessToken);
      await _storage.write(key: 'refreshToken', value: _refreshToken);
      await _storage.write(key: 'userData', value: user.toStorage());
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // — Clear everything
  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _apiService.accessToken = null;
    _apiService.refreshToken = null;

    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'userData');
    notifyListeners();
  }

  // — Manual refresh (if you ever need to)
  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) return;
    try {
      final tokens = await _apiService.refreshAuthToken(_refreshToken!);
      _accessToken = tokens['accessToken'];
      _refreshToken = tokens['refreshToken'];

      _apiService.accessToken = _accessToken;
      _apiService.refreshToken = _refreshToken;

      await _storage.write(key: 'accessToken', value: _accessToken);
      await _storage.write(key: 'refreshToken', value: _refreshToken);
    } catch (_) {
      await logout();
    }
  }
}
