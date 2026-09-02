import 'package:flutter/foundation.dart';

class ApiConstants {
  // Default base URL for local development
  // - Physical Android device via USB: http://127.0.0.1:5000 (after `adb reverse tcp:5000 tcp:5000`)
  // - Physical Android device via Wi-Fi: set customBaseUrl to 'http://192.168.0.135:5000'
  // - Android Emulator: http://10.0.2.2:5000
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  // Override base URL dynamically if running on a physical phone on local Wi-Fi
  static String? customBaseUrl;
  static String get activeBaseUrl => customBaseUrl ?? baseUrl;

  // 1. Authentication Endpoints
  static const String riderLogin = '/api/v1/auth/rider/login';
  static const String riderRegister = '/api/v1/auth/rider/register';
  static const String getMe = '/api/v1/auth/me';
  static const String changePassword = '/api/v1/auth/change-password';
  static const String updateFcmToken = '/api/v1/auth/fcm-token';
  static const String logout = '/api/v1/auth/logout';

  // 2. Rider Operations & GPS Tracking
  static const String riderStatus = '/api/v1/rider/status';
  static const String riderLocation = '/api/v1/rider/location';
  static const String assignedDeliveries = '/api/v1/rider/assigned';
  static const String activeDelivery = '/api/v1/rider/active';
  static String acceptDelivery(String id) => '/api/v1/rider/deliveries/$id/accept';
  static String rejectDelivery(String id) => '/api/v1/rider/deliveries/$id/reject';
  static String updateDeliveryStatus(String id) => '/api/v1/rider/deliveries/$id/status';
  static String verifyDeliveryOtp(String id) => '/api/v1/rider/deliveries/$id/verify-otp';
  static const String riderHistory = '/api/v1/rider/history';
  static const String riderProfile = '/api/v1/rider/profile';
  static const String riderNotifications = '/api/v1/rider/notifications';

  // 3. Notifications Management
  static String markNotificationRead(String id) => '/api/v1/notifications/$id/read';
  static const String markAllNotificationsRead = '/api/v1/notifications/read-all';

  // 4. Health Check
  static const String healthCheck = '/api/v1/health';
}
