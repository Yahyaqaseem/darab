import 'package:flutter/material.dart';

class RoadReportModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String roadName;
  final String roadSegmentId;
  final int? bearing;
  final double confidence;
  final int confirmationsCount;
  final int rejectionsCount;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int? distanceMeters;

  RoadReportModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.roadName,
    required this.roadSegmentId,
    this.bearing,
    required this.confidence,
    required this.confirmationsCount,
    required this.rejectionsCount,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.distanceMeters,
  });

  factory RoadReportModel.fromJson(Map<String, dynamic> json) {
    return RoadReportModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'OTHER',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      roadName: json['roadName'] ?? json['road_name'] ?? 'طريق عام',
      roadSegmentId: json['roadSegmentId'] ?? json['road_segment_id'] ?? '',
      bearing: json['bearing'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      confirmationsCount: json['confirmationsCount'] ?? json['confirmations_count'] ?? 0,
      rejectionsCount: json['rejectionsCount'] ?? json['rejections_count'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt']) ?? DateTime.now().add(const Duration(minutes: 30))
          : DateTime.now().add(const Duration(minutes: 30)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      distanceMeters: json['distanceMeters'] != null ? (json['distanceMeters'] as num).toInt() : null,
    );
  }

  IconData get icon {
    switch (type) {
      case 'ACCIDENT':
        return Icons.car_crash;
      case 'HEAVY_TRAFFIC':
        return Icons.traffic;
      case 'CHECKPOINT':
        return Icons.security;
      case 'CLOSURE':
        return Icons.do_not_disturb_on;
      case 'POTHOLE':
        return Icons.warning_rounded;
      case 'WATER_ACCUMULATION':
        return Icons.water_drop;
      case 'DETOUR':
        return Icons.alt_route;
      case 'BROKEN_CAR':
        return Icons.build_circle;
      default:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case 'ACCIDENT':
      case 'CLOSURE':
        return const Color(0xFFEF4444);
      case 'HEAVY_TRAFFIC':
        return const Color(0xFFF59E0B);
      case 'CHECKPOINT':
        return const Color(0xFF3B82F6);
      case 'POTHOLE':
        return const Color(0xFFD97706);
      case 'WATER_ACCUMULATION':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF10B981);
    }
  }
}

class RoadQuestionModel {
  final String id;
  final String requesterUserId;
  final String questionType;
  final String title;
  final String? customText;
  final double latitude;
  final double longitude;
  final int bearing;
  final String roadName;
  final int answersYes;
  final int answersNo;
  final int answersNotSure;
  final int totalAnswers;
  final bool isAggregated;
  final String? aggregatedSummary;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int? distanceMeters;

  RoadQuestionModel({
    required this.id,
    required this.requesterUserId,
    required this.questionType,
    required this.title,
    this.customText,
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.roadName,
    required this.answersYes,
    required this.answersNo,
    required this.answersNotSure,
    required this.totalAnswers,
    required this.isAggregated,
    this.aggregatedSummary,
    required this.expiresAt,
    required this.createdAt,
    this.distanceMeters,
  });

  factory RoadQuestionModel.fromJson(Map<String, dynamic> json) {
    return RoadQuestionModel(
      id: json['id'] ?? '',
      requesterUserId: json['requesterUserId'] ?? '',
      questionType: json['questionType'] ?? 'TRAFFIC',
      title: json['title'] ?? '',
      customText: json['customText'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      bearing: json['bearing'] ?? 0,
      roadName: json['roadName'] ?? 'طريق عام',
      answersYes: json['answersYes'] ?? 0,
      answersNo: json['answersNo'] ?? 0,
      answersNotSure: json['answersNotSure'] ?? 0,
      totalAnswers: json['totalAnswers'] ?? 0,
      isAggregated: json['isAggregated'] ?? false,
      aggregatedSummary: json['aggregatedSummary'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt']) ?? DateTime.now().add(const Duration(minutes: 15))
          : DateTime.now().add(const Duration(minutes: 15)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      distanceMeters: json['distanceMeters'] != null ? (json['distanceMeters'] as num).toInt() : null,
    );
  }
}

class FuelStationModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? nameKu;
  final double latitude;
  final double longitude;
  final String city;
  final String address;
  final String phone;
  final int petrolPrice;
  final int premiumPrice;
  final int dieselPrice;
  final bool isPetrolAvailable;
  final String crowdLevel; // LOW, MEDIUM, HIGH
  final double rating;
  final bool isVerified;
  final DateTime priceUpdatedAt;
  final String priceSource;
  final double? distanceKm;

  FuelStationModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.nameKu,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.address,
    required this.phone,
    required this.petrolPrice,
    required this.premiumPrice,
    required this.dieselPrice,
    required this.isPetrolAvailable,
    required this.crowdLevel,
    required this.rating,
    required this.isVerified,
    required this.priceUpdatedAt,
    required this.priceSource,
    this.distanceKm,
  });

  factory FuelStationModel.fromJson(Map<String, dynamic> json) {
    return FuelStationModel(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'],
      nameKu: json['nameKu'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      petrolPrice: json['petrolPrice'] ?? 850,
      premiumPrice: json['premiumPrice'] ?? 1150,
      dieselPrice: json['dieselPrice'] ?? 750,
      isPetrolAvailable: json['isPetrolAvailable'] ?? true,
      crowdLevel: json['crowdLevel'] ?? 'LOW',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      isVerified: json['isVerified'] ?? false,
      priceUpdatedAt: json['priceUpdatedAt'] != null
          ? DateTime.tryParse(json['priceUpdatedAt']) ?? DateTime.now()
          : DateTime.now(),
      priceSource: json['priceSource'] ?? 'COMMUNITY',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  String get crowdText {
    switch (crowdLevel) {
      case 'LOW':
        return 'منخفض (لا يوجد طابور)';
      case 'MEDIUM':
        return 'متوسط (5-10 دقائق)';
      case 'HIGH':
        return 'مزدحم جداً';
      default:
        return 'غير محدد';
    }
  }

  Color get crowdColor {
    switch (crowdLevel) {
      case 'LOW':
        return const Color(0xFF22C55E);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'HIGH':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}

class PlaceModel {
  final String id;
  final String categoryKey;
  final String nameAr;
  final String? nameEn;
  final String? nameKu;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final String openingHours;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final List<String> photos;
  final double? distanceKm;

  PlaceModel({
    required this.id,
    required this.categoryKey,
    required this.nameAr,
    this.nameEn,
    this.nameKu,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.rating,
    required this.reviewsCount,
    required this.isVerified,
    required this.photos,
    this.distanceKm,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] ?? '',
      categoryKey: json['categoryKey'] ?? 'mechanic',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'],
      nameKu: json['nameKu'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      openingHours: json['openingHours'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: json['reviewsCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class TripModel {
  final String id;
  final String startName;
  final String endName;
  final double distanceKm;
  final int durationSeconds;
  final String durationFormatted;
  final double avgSpeedKmh;
  final double trustedMaxSpeedKmh;
  final double rawGpsMaxSpeedKmh;
  final bool hasAnomalyFiltered;
  final int stopsCount;
  final int trafficDelaySeconds;
  final DateTime createdAt;

  TripModel({
    required this.id,
    required this.startName,
    required this.endName,
    required this.distanceKm,
    required this.durationSeconds,
    required this.durationFormatted,
    required this.avgSpeedKmh,
    required this.trustedMaxSpeedKmh,
    required this.rawGpsMaxSpeedKmh,
    required this.hasAnomalyFiltered,
    required this.stopsCount,
    required this.trafficDelaySeconds,
    required this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      startName: json['startName'] ?? json['start_name'] ?? 'نقطة الانطلاق',
      endName: json['endName'] ?? json['end_name'] ?? 'الوجهة',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      durationFormatted: json['durationFormatted'] ?? '',
      avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      trustedMaxSpeedKmh: (json['trustedMaxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      rawGpsMaxSpeedKmh: (json['rawGpsMaxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      hasAnomalyFiltered: json['hasAnomalyFiltered'] ?? false,
      stopsCount: json['stopsCount'] ?? 0,
      trafficDelaySeconds: json['trafficDelaySeconds'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
