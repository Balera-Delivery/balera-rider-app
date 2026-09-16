import 'package:intl/intl.dart';

enum DeliveryStatus {
  assigned,
  accepted,
  arrivedAtPickup,
  pickedUp,
  onTheWay,
  arrivedAtLocation,
  delivered,
  completed,
  cancelled,
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.accepted:
        return 'Accepted';
      case DeliveryStatus.arrivedAtPickup:
        return 'Arrived at Pickup';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.onTheWay:
        return 'On The Way';
      case DeliveryStatus.arrivedAtLocation:
        return 'Arrived at Location';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  String toBackendString() {
    switch (this) {
      case DeliveryStatus.assigned:
        return 'ASSIGNED';
      case DeliveryStatus.accepted:
        return 'ACCEPTED';
      case DeliveryStatus.arrivedAtPickup:
        return 'ARRIVED_AT_PICKUP';
      case DeliveryStatus.pickedUp:
        return 'PICKED_UP';
      case DeliveryStatus.onTheWay:
        return 'ON_THE_WAY';
      case DeliveryStatus.arrivedAtLocation:
      case DeliveryStatus.delivered:
        return 'DELIVERED';
      case DeliveryStatus.completed:
        return 'COMPLETED';
      case DeliveryStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static DeliveryStatus fromBackendString(String? status) {
    if (status == null) return DeliveryStatus.assigned;
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'ASSIGNED':
        return DeliveryStatus.assigned;
      case 'ACCEPTED':
        return DeliveryStatus.accepted;
      case 'ARRIVED_AT_PICKUP':
        return DeliveryStatus.arrivedAtPickup;
      case 'PICKED_UP':
        return DeliveryStatus.pickedUp;
      case 'ON_THE_WAY':
        return DeliveryStatus.onTheWay;
      case 'DELIVERED':
        return DeliveryStatus.delivered;
      case 'COMPLETED':
        return DeliveryStatus.completed;
      case 'CANCELLED':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.assigned;
    }
  }
}

class DeliveryOrder {
  final String id;
  final String trackingCode;
  final String assignedTime;
  final String pickupLocation;
  final String pickupAddressDetails;
  final String pickupPhone;
  final String dropoffLocation;
  final String dropoffAddressDetails;
  final String dropoffPhone;
  final String eta;
  final String distance;
  final String itemType;
  final String itemDescription;
  final String customerName;
  final String customerPhone;
  final String receiverName;
  final String receiverPhone;
  final String specialInstructions;
  final double paymentAmount;
  DeliveryStatus status;
  final String otpCode;
  String? completedAt;
  final String date;
  final bool isUpcoming;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;

  String get displayId => trackingCode.isNotEmpty ? trackingCode : id;

  DeliveryOrder({
    required this.id,
    this.trackingCode = '',
    required this.assignedTime,
    required this.pickupLocation,
    required this.pickupAddressDetails,
    required this.pickupPhone,
    required this.dropoffLocation,
    required this.dropoffAddressDetails,
    required this.dropoffPhone,
    required this.eta,
    required this.distance,
    required this.itemType,
    required this.itemDescription,
    required this.customerName,
    required this.customerPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.specialInstructions,
    required this.paymentAmount,
    required this.status,
    required this.otpCode,
    this.completedAt,
    required this.date,
    this.isUpcoming = false,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString()).toLocal();
      } catch (_) {}
    }

    final timeFormatter = DateFormat('hh:mm a');
    final dateFormatter = DateFormat('MMM dd, yyyy');

    final customer = json['customer'] is Map ? json['customer'] as Map<String, dynamic> : null;
    final customerName = customer?['fullName']?.toString() ?? 'Balerra Customer';
    final customerPhone = customer?['phoneNumber']?.toString() ?? '+251 911 000 000';

    final pickup = json['pickupLocation']?.toString() ?? 'Pickup Point';
    final destination = json['destination']?.toString() ?? 'Destination';
    final recName = json['receiverName']?.toString() ?? customerName;
    final recPhone = json['receiverPhone']?.toString() ?? customerPhone;

    final rawStatus = json['status']?.toString() ?? 'ASSIGNED';
    final parsedStatus = DeliveryStatusExtension.fromBackendString(rawStatus);

    final rawId = json['id']?.toString() ?? json['trackingCode']?.toString() ?? '#DLV';
    final rawTracking = json['trackingCode']?.toString() ?? rawId;

    final extractedOtp = json['otpCode']?.toString() ??
        json['otp']?['otpCode']?.toString() ??
        json['otp']?['code']?.toString() ??
        '';

    return DeliveryOrder(
      id: rawId,
      trackingCode: rawTracking,
      assignedTime: timeFormatter.format(createdAt),
      pickupLocation: pickup,
      pickupAddressDetails: pickup,
      pickupPhone: customerPhone,
      dropoffLocation: destination,
      dropoffAddressDetails: destination,
      dropoffPhone: recPhone,
      eta: '25 min',
      distance: '3.5 km',
      itemType: json['itemType']?.toString() ?? 'Package',
      itemDescription: json['itemDescription']?.toString() ?? 'Delivery package',
      customerName: customerName,
      customerPhone: customerPhone,
      receiverName: recName,
      receiverPhone: recPhone,
      specialInstructions: json['specialInstructions']?.toString() ?? 'Handle with standard delivery care.',
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 100.0,
      status: parsedStatus,
      otpCode: extractedOtp,
      completedAt: json['status'] == 'COMPLETED' ? timeFormatter.format(createdAt) : null,
      date: '${dateFormatter.format(createdAt)} • ${timeFormatter.format(createdAt)}',
      isUpcoming: parsedStatus == DeliveryStatus.assigned,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      destinationLatitude: (json['destinationLatitude'] as num?)?.toDouble(),
      destinationLongitude: (json['destinationLongitude'] as num?)?.toDouble(),
    );
  }

  DeliveryOrder copyWith({
    String? id,
    String? trackingCode,
    String? assignedTime,
    String? pickupLocation,
    String? pickupAddressDetails,
    String? pickupPhone,
    String? dropoffLocation,
    String? dropoffAddressDetails,
    String? dropoffPhone,
    String? eta,
    String? distance,
    String? itemType,
    String? itemDescription,
    String? customerName,
    String? customerPhone,
    String? receiverName,
    String? receiverPhone,
    String? specialInstructions,
    double? paymentAmount,
    DeliveryStatus? status,
    String? otpCode,
    String? completedAt,
    String? date,
    bool? isUpcoming,
    double? pickupLatitude,
    double? pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      trackingCode: trackingCode ?? this.trackingCode,
      assignedTime: assignedTime ?? this.assignedTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddressDetails: pickupAddressDetails ?? this.pickupAddressDetails,
      pickupPhone: pickupPhone ?? this.pickupPhone,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      dropoffAddressDetails: dropoffAddressDetails ?? this.dropoffAddressDetails,
      dropoffPhone: dropoffPhone ?? this.dropoffPhone,
      eta: eta ?? this.eta,
      distance: distance ?? this.distance,
      itemType: itemType ?? this.itemType,
      itemDescription: itemDescription ?? this.itemDescription,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      status: status ?? this.status,
      otpCode: otpCode ?? this.otpCode,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
      isUpcoming: isUpcoming ?? this.isUpcoming,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
    );
  }
}
