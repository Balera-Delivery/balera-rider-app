import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../models/rider_profile.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  RiderProfile? _rider;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  RiderProfile? get rider => _rider;
  String? get errorMessage => _errorMessage;
  String get phoneNumber => _rider?.phoneNumber ?? '';
  String get email => _rider?.email ?? '';

  Future<void> init() async {
    await _apiClient.init();
    if (_apiClient.token != null && _apiClient.token!.isNotEmpty) {
      await checkAuthSession();
    }
  }

  Future<bool> checkAuthSession() async {
    try {
      if (_apiClient.token == null || _apiClient.token!.isEmpty) {
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }

      final data = await _apiClient.get(ApiConstants.getMe);
      if (data is Map<String, dynamic>) {
        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
        _rider = RiderProfile.fromJson(userMap);
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } catch (_) {
      _isLoggedIn = false;
      await _apiClient.clearToken();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.riderLogin,
        body: {
          'email': email.trim(),
          'password': password.trim(),
        },
      );

      if (response is Map<String, dynamic>) {
        final token = response['token']?.toString();
        if (token != null) {
          await _apiClient.saveToken(token);
        }

        if (response['rider'] is Map<String, dynamic>) {
          _rider = RiderProfile.fromJson(response['rider']);
        }

        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw ApiException('Unexpected response from server.');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerRider({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? vehicleInfo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.riderRegister,
        body: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'password': password.trim(),
          'vehicleInfo': vehicleInfo?.trim(),
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'message': 'Registration submitted for admin review'};
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.put(
        ApiConstants.changePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _apiClient.put(
        ApiConstants.updateFcmToken,
        body: {'fcmToken': fcmToken},
      );
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (_) {}
    await _apiClient.clearToken();
    _isLoggedIn = false;
    _rider = null;
    notifyListeners();
  }
}
