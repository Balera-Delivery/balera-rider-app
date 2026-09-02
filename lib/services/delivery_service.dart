import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../models/delivery_order.dart';
import '../models/rider_profile.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class DeliveryService extends ChangeNotifier {
  static final DeliveryService _instance = DeliveryService._internal();
  factory DeliveryService() => _instance;

  DeliveryService._internal() {
    _initDefaults();
  }

  final ApiClient _apiClient = ApiClient();

  late RiderProfile _riderProfile;
  final List<DeliveryOrder> _deliveries = [];
  final List<DeliveryOrder> _historyDeliveries = [];
  final List<NotificationItem> _notifications = [];
  DeliveryOrder? _currentActiveDelivery;

  bool _isLoadingDeliveries = false;
  bool _isLoadingHistory = false;
  bool _isLoadingProfile = false;
  bool _isLoadingNotifications = false;

  RiderProfile get riderProfile => _riderProfile;
  List<DeliveryOrder> get deliveries => _deliveries;
  List<DeliveryOrder> get historyDeliveries => _historyDeliveries;
  List<NotificationItem> get notifications => _notifications;
  bool get isLoadingDeliveries => _isLoadingDeliveries;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isLoadingNotifications => _isLoadingNotifications;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  List<DeliveryOrder> get activeDeliveries => _deliveries
      .where((d) => d.status != DeliveryStatus.completed && d.status != DeliveryStatus.cancelled)
      .toList();

  List<DeliveryOrder> get upcomingDeliveries =>
      _deliveries.where((d) => d.status == DeliveryStatus.assigned).toList();

  List<DeliveryOrder> get completedDeliveries => _historyDeliveries.isNotEmpty
      ? _historyDeliveries
      : _deliveries.where((d) => d.status == DeliveryStatus.completed).toList();

  List<DeliveryOrder> get cancelledDeliveries =>
      _deliveries.where((d) => d.status == DeliveryStatus.cancelled).toList();

  DeliveryOrder? get currentDelivery => _currentActiveDelivery ?? (activeDeliveries.isNotEmpty ? activeDeliveries.first : null);

  void _initDefaults() {
    _riderProfile = RiderProfile(
      id: 'RDR-001',
      fullName: 'Balerra Rider',
      phoneNumber: '+251 911 000 000',
      email: 'rider@balera.com',
      vehicleType: 'TVS Apache RTR',
      plateNumber: 'AA-3-4921',
      rating: 4.9,
      isOnline: true,
      todayAssigned: 0,
      todayCompleted: 0,
      todayEarnings: 0.0,
      totalDeliveries: 0,
      totalEarnings: 0.0,
    );
  }

  // Refreshes all core datasets when user logs in or pulls to refresh
  Future<void> refreshAll() async {
    await Future.wait([
      fetchProfile(),
      fetchAssignedDeliveries(),
      fetchActiveDelivery(),
      fetchNotifications(),
      fetchDeliveryHistory(),
    ]);
  }

  // 1. Rider Profile (GET /api/v1/rider/profile)
  Future<void> fetchProfile() async {
    _isLoadingProfile = true;
    notifyListeners();
    try {
      final data = await _apiClient.get(ApiConstants.riderProfile);
      if (data is Map<String, dynamic>) {
        _riderProfile = RiderProfile.fromJson(data);
      }
    } catch (_) {
      // Keep existing profile on network failure
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // 2. Update Profile (PUT /api/v1/rider/profile)
  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String vehicleType,
    required String plateNumber,
  }) async {
    try {
      final payload = {
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'vehicleInfo': '$vehicleType Plate $plateNumber',
      };
      final data = await _apiClient.put(ApiConstants.riderProfile, body: payload);
      if (data is Map<String, dynamic>) {
        _riderProfile = RiderProfile.fromJson(data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // 3. Toggle Online Availability (PUT /api/v1/rider/status)
  Future<void> toggleOnlineStatus(bool online) async {
    final prev = _riderProfile.isOnline;
    _riderProfile.isOnline = online;
    notifyListeners();

    try {
      await _apiClient.put(
        ApiConstants.riderStatus,
        body: {'status': online ? 'ONLINE' : 'OFFLINE'},
      );
    } catch (e) {
      // Revert if API call fails
      _riderProfile.isOnline = prev;
      notifyListeners();
      rethrow;
    }
  }

  // 4. Update GPS Location (PUT /api/v1/rider/location)
  Future<void> updateLocation(double latitude, double longitude, {double? heading}) async {
    try {
      await _apiClient.put(
        ApiConstants.riderLocation,
        body: {
          'latitude': latitude,
          'longitude': longitude,
          if (heading != null) 'heading': heading,
        },
      );
    } catch (_) {
      // Ignore background heartbeat failures
    }
  }

  // 5. Fetch Assigned Deliveries (GET /api/v1/rider/assigned)
  Future<void> fetchAssignedDeliveries() async {
    _isLoadingDeliveries = true;
    notifyListeners();

    try {
      final data = await _apiClient.get(ApiConstants.assignedDeliveries);
      if (data is List) {
        _deliveries.clear();
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            _deliveries.add(DeliveryOrder.fromJson(item));
          }
        }
        _riderProfile.todayAssigned = _deliveries.length;
      }
    } catch (_) {
      // Keep existing cache if network drops
    } finally {
      _isLoadingDeliveries = false;
      notifyListeners();
    }
  }

  // 6. Fetch Active Delivery (GET /api/v1/rider/active)
  Future<void> fetchActiveDelivery() async {
    try {
      final data = await _apiClient.get(ApiConstants.activeDelivery);
      if (data is Map<String, dynamic>) {
        _currentActiveDelivery = DeliveryOrder.fromJson(data);
      } else {
        _currentActiveDelivery = null;
      }
      notifyListeners();
    } catch (_) {
      // Ignore active delivery load error
    }
  }

  // 7. Accept Delivery (POST /api/v1/rider/deliveries/{id}/accept)
  Future<bool> acceptDelivery(String deliveryId) async {
    try {
      await _apiClient.post(ApiConstants.acceptDelivery(deliveryId));
      await fetchAssignedDeliveries();
      await fetchActiveDelivery();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 8. Reject Delivery (POST /api/v1/rider/deliveries/{id}/reject)
  Future<bool> rejectDelivery(String deliveryId, {String reason = 'Motorcycle maintenance'}) async {
    try {
      await _apiClient.post(
        ApiConstants.rejectDelivery(deliveryId),
        body: {'reason': reason},
      );
      await fetchAssignedDeliveries();
      await fetchActiveDelivery();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 9. Update Delivery Status (PUT /api/v1/rider/deliveries/{id}/status)
  // Allowed statuses: ACCEPTED, ARRIVED_AT_PICKUP, PICKED_UP, ON_THE_WAY, DELIVERED
  Future<bool> updateDeliveryStatus(String deliveryId, DeliveryStatus newStatus, {String? notes}) async {
    if (newStatus == DeliveryStatus.completed) {
      throw ApiException('Delivery cannot be completed directly. Customer OTP verification is required.');
    }
    try {
      final backendStatus = newStatus.toBackendString();
      await _apiClient.put(
        ApiConstants.updateDeliveryStatus(deliveryId),
        body: {
          'status': backendStatus,
          if (notes != null) 'notes': notes,
        },
      );

      // Local update for instant UI feedback
      final index = _deliveries.indexWhere((d) => d.id == deliveryId);
      if (index != -1) {
        _deliveries[index].status = newStatus;
      }
      if (_currentActiveDelivery != null && _currentActiveDelivery!.id == deliveryId) {
        _currentActiveDelivery!.status = newStatus;
      }
      notifyListeners();

      await fetchActiveDelivery();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 10. Verify 6-digit OTP to complete delivery (POST /api/v1/rider/deliveries/{id}/verify-otp)
  Future<bool> verifyOtp(String deliveryId, String enteredOtp) async {
    try {
      await _apiClient.post(
        ApiConstants.verifyDeliveryOtp(deliveryId),
        body: {'otpCode': enteredOtp.trim()},
      );

      // Update local state
      final index = _deliveries.indexWhere((d) => d.id == deliveryId);
      if (index != -1) {
        _deliveries[index].status = DeliveryStatus.completed;
      }
      if (_currentActiveDelivery != null && _currentActiveDelivery!.id == deliveryId) {
        _currentActiveDelivery = null;
      }

      _riderProfile.todayCompleted += 1;
      _riderProfile.totalDeliveries += 1;

      notifyListeners();
      await fetchDeliveryHistory();
      await fetchAssignedDeliveries();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 11. Fetch Delivery History (GET /api/v1/rider/history)
  Future<void> fetchDeliveryHistory({int page = 1, int limit = 20}) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final data = await _apiClient.get(
        ApiConstants.riderHistory,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (data is Map<String, dynamic> && data['deliveries'] is List) {
        final list = data['deliveries'] as List;
        _historyDeliveries.clear();
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            _historyDeliveries.add(DeliveryOrder.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Keep existing history
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // 12. Fetch Notifications (GET /api/v1/rider/notifications)
  Future<void> fetchNotifications({int page = 1, int limit = 20}) async {
    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final data = await _apiClient.get(
        ApiConstants.riderNotifications,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (data is Map<String, dynamic> && data['notifications'] is List) {
        final list = data['notifications'] as List;
        _notifications.clear();
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            _notifications.add(NotificationItem.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Keep existing notifications
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  // 13. Mark Single Notification as Read (PUT /api/v1/notifications/{id}/read)
  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }

    try {
      await _apiClient.put(ApiConstants.markNotificationRead(id));
    } catch (_) {}
  }

  // 14. Mark All Notifications as Read (PUT /api/v1/notifications/read-all)
  Future<void> markAllNotificationsAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await _apiClient.put(ApiConstants.markAllNotificationsRead);
    } catch (_) {}
  }

  DeliveryOrder? getDeliveryById(String id) {
    try {
      return _deliveries.firstWhere((d) => d.id == id);
    } catch (_) {
      try {
        return _historyDeliveries.firstWhere((d) => d.id == id);
      } catch (_) {
        return null;
      }
    }
  }
}
