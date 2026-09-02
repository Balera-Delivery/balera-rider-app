class RiderProfile {
  final String id;
  String fullName;
  String phoneNumber;
  String email;
  String vehicleType;
  String plateNumber;
  double rating;
  bool isOnline;
  String accountStatus;
  int todayAssigned;
  int todayCompleted;
  double todayEarnings;
  int totalDeliveries;
  double totalEarnings;
  String profileImageUrl;

  RiderProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.vehicleType,
    required this.plateNumber,
    required this.rating,
    this.isOnline = true,
    this.accountStatus = 'ACTIVE',
    required this.todayAssigned,
    required this.todayCompleted,
    required this.todayEarnings,
    required this.totalDeliveries,
    required this.totalEarnings,
    this.profileImageUrl = '',
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    final vehicleInfo = json['vehicleInfo']?.toString() ?? 'TVS Motorcycle';
    // Attempt parsing vehicle and plate if combined (e.g. "TVS Motorcycle Plate AA-2-4592")
    String vType = vehicleInfo;
    String pNumber = 'AA-2-4592';
    if (vehicleInfo.contains('Plate')) {
      final parts = vehicleInfo.split('Plate');
      vType = parts[0].trim();
      pNumber = parts.length > 1 ? parts[1].trim() : 'AA-2-4592';
    }

    final availability = json['availabilityStatus']?.toString().toUpperCase();
    final bool online = availability == 'ONLINE';

    return RiderProfile(
      id: json['id']?.toString() ?? 'RDR-001',
      fullName: json['fullName']?.toString() ?? 'Balerra Rider',
      phoneNumber: json['phoneNumber']?.toString() ?? '+251 911 000 000',
      email: json['email']?.toString() ?? 'rider@balera.com',
      vehicleType: vType.isNotEmpty ? vType : 'Motorcycle',
      plateNumber: pNumber,
      rating: 4.9,
      isOnline: online,
      accountStatus: json['accountStatus']?.toString() ?? 'ACTIVE',
      todayAssigned: (json['todayAssigned'] as num?)?.toInt() ?? 0,
      todayCompleted: (json['todayCompleted'] as num?)?.toInt() ?? 0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      profileImageUrl: json['profileImageUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'vehicleInfo': '$vehicleType Plate $plateNumber',
      'availabilityStatus': isOnline ? 'ONLINE' : 'OFFLINE',
      'accountStatus': accountStatus,
    };
  }

  RiderProfile copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? vehicleType,
    String? plateNumber,
    double? rating,
    bool? isOnline,
    String? accountStatus,
    int? todayAssigned,
    int? todayCompleted,
    double? todayEarnings,
    int? totalDeliveries,
    double? totalEarnings,
    String? profileImageUrl,
  }) {
    return RiderProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      rating: rating ?? this.rating,
      isOnline: isOnline ?? this.isOnline,
      accountStatus: accountStatus ?? this.accountStatus,
      todayAssigned: todayAssigned ?? this.todayAssigned,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
