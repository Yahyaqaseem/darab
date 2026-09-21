import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;
  String _baseUrl = AppConstants.defaultApiUrl;

  ApiService({String? baseUrl}) {
    _baseUrl = baseUrl ?? AppConstants.defaultApiUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  // --- Auth ---
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final res = await _dio.post('/auth/request-otp', data: {'phoneNumber': phoneNumber});
      return res.data;
    } catch (e) {
      // Mock Fallback
      return {'success': true, 'message': 'تم إرسال رمز التحقق التجريبي (123456)'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {String? username}) async {
    try {
      final res = await _dio.post('/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'username': username,
      });
      if (res.data['accessToken'] != null) {
        setAuthToken(res.data['accessToken']);
      }
      return res.data;
    } catch (e) {
      // Mock Fallback
      final mockToken = 'mock_jwt_token_iraq_2026';
      setAuthToken(mockToken);
      return {
        'accessToken': mockToken,
        'user': {
          'id': '00000000-0000-0000-0000-000000000001',
          'phoneNumber': phoneNumber,
          'username': username ?? 'سائق_درب',
          'trustLevel': 'ROAD_EXPERT',
          'reputationScore': 185,
        }
      };
    }
  }

  // --- Road Reports ---
  Future<List<RoadReportModel>> getNearbyReports({double lat = 36.1911, double lng = 44.0091, double radius = 30000}) async {
    final res = await _dio.get('/reports/nearby', queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
    final list = res.data as List;
    return list.map((e) => RoadReportModel.fromJson(e)).toList();
  }

  Future<RoadReportModel> createReport(Map<String, dynamic> reportData) async {
    final res = await _dio.post('/reports', data: reportData);
    final data = res.data;
    if (data['report'] != null) {
      return RoadReportModel.fromJson(data['report']);
    }
    return RoadReportModel.fromJson(data);
  }

  Future<bool> confirmReport(String reportId, String vote, {double? userLat, double? userLng}) async {
    await _dio.post('/reports/$reportId/confirm', data: {
      'vote': vote,
      if (userLat != null) 'userLatitude': userLat,
      if (userLng != null) 'userLongitude': userLng,
    });
    return true;
  }

  // --- Road Call (نداء الطريق) ---
  Future<List<RoadQuestionModel>> getActiveRoadQuestions({double lat = 36.1911, double lng = 44.0091, int? bearing}) async {
    final res = await _dio.get('/road-call/active', queryParameters: {'lat': lat, 'lng': lng, 'bearing': bearing});
    final list = res.data as List;
    return list.map((e) => RoadQuestionModel.fromJson(e)).toList();
  }

  Future<RoadQuestionModel> askRoadQuestion(Map<String, dynamic> data) async {
    final res = await _dio.post('/road-call/ask', data: data);
    return RoadQuestionModel.fromJson(res.data);
  }

  Future<bool> answerRoadQuestion(String questionId, String answer) async {
    await _dio.post('/road-call/$questionId/answer', data: {'answer': answer});
    return true;
  }

  // --- Fuel Stations ---
  Future<List<FuelStationModel>> getNearbyFuelStations({double lat = 36.1911, double lng = 44.0091, double radius = 30000}) async {
    final res = await _dio.get('/fuel/nearby', queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
    final list = res.data as List;
    return list.map((e) => FuelStationModel.fromJson(e)).toList();
  }

  Future<bool> updateFuelReport(String stationId, Map<String, dynamic> data) async {
    await _dio.post('/fuel/$stationId/report', data: data);
    return true;
  }

  // --- Places ---
  Future<List<PlaceModel>> getNearbyPlaces({double lat = 36.1911, double lng = 44.0091, String? category, double radius = 30000}) async {
    final res = await _dio.get('/places/nearby', queryParameters: {'lat': lat, 'lng': lng, 'category': category, 'radius': radius});
    final list = res.data as List;
    return list.map((e) => PlaceModel.fromJson(e)).toList();
  }

  Future<List<PlaceModel>> searchPlaces(String query, {double? lat, double? lng}) async {
    final res = await _dio.get('/places/search', queryParameters: {'q': query, 'lat': lat, 'lng': lng});
    final list = res.data as List;
    return list.map((e) => PlaceModel.fromJson(e)).toList();
  }

  Future<bool> addPlaceReview(String placeId, int rating, String? comment) async {
    await _dio.post('/places/$placeId/reviews', data: {'rating': rating, 'comment': comment});
    return true;
  }

  // --- Navigation & Routes ---
  Future<Map<String, dynamic>> calculateRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originName,
    String? destName,
  }) async {
    try {
      final res = await _dio.post('/navigation/calculate-routes', data: {
        'originLat': originLat,
        'originLng': originLng,
        'destLat': destLat,
        'destLng': destLng,
        'originName': originName,
        'destName': destName,
      });
      return res.data;
    } catch (e) {
      return _getMockRouteCalculation(destName ?? 'دهوك');
    }
  }

  // --- Profile & Trips ---
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _dio.get('/users/me');
      return res.data;
    } catch (e) {
      return {
        'user': {
          'id': '00000000-0000-0000-0000-000000000001',
          'phoneNumber': '+9647501234567',
          'username': 'سائق_أربيل_الخبير',
          'trustLevel': 'ROAD_EXPERT',
          'reputationScore': 185,
          'helpfulAnswersCount': 24,
          'verifiedReportsCount': 38,
        },
        'vehicles': [
          {'id': 'v1', 'make': 'Toyota', 'model': 'Land Cruiser', 'year': 2023, 'isPrimary': true},
          {'id': 'v2', 'make': 'Kia', 'model': 'Sportage', 'year': 2021, 'isPrimary': false},
        ],
        'badges': [
          {'slug': 'eye_of_erbil', 'titleAr': 'عين أربيل', 'icon': 'visibility'},
          {'slug': 'road_expert', 'titleAr': 'خبير الطرق', 'icon': 'verified'},
        ],
        'stats': {
          'totalDistanceKm': 1450.5,
          'totalTripsCount': 42,
          'pointsToNextLevel': 115,
          'nextLevelTitle': 'عين المدينة',
        }
      };
    }
  }

  Future<List<TripModel>> getUserTrips() async {
    try {
      final res = await _dio.get('/trips');
      final list = res.data as List;
      return list.map((e) => TripModel.fromJson(e)).toList();
    } catch (e) {
      return [
        TripModel(
          id: 'demo-trip-1',
          startName: 'أربيل - بارك شاندر',
          endName: 'دهوك - المركز',
          distanceKm: 155.4,
          durationSeconds: 8280,
          durationFormatted: '2 ساعة و 18 دقيقة',
          avgSpeedKmh: 67.5,
          trustedMaxSpeedKmh: 124.0,
          rawGpsMaxSpeedKmh: 250.0,
          hasAnomalyFiltered: true,
          stopsCount: 1,
          trafficDelaySeconds: 480,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        )
      ];
    }
  }

  // Mock Generators
  List<RoadReportModel> _getMockReports() {
    return [
      RoadReportModel(
        id: 'rep-1',
        type: 'HEAVY_TRAFFIC',
        title: 'زحمة شديدة عند سيطرة الكلك',
        description: 'طابور طويل من السيارات قبل السيطرة بمسافة 1.5 كم',
        latitude: 36.2625,
        longitude: 43.6667,
        roadName: 'طريق أربيل - دهوك M10',
        roadSegmentId: 'erbil-duhok-m10',
        confidence: 0.92,
        confirmationsCount: 8,
        rejectionsCount: 1,
        status: 'CONFIRMED',
        expiresAt: DateTime.now().add(const Duration(minutes: 25)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        distanceMeters: 3200,
      ),
      RoadReportModel(
        id: 'rep-2',
        type: 'ACCIDENT',
        title: 'حادث سير على شارع 100 متري',
        description: 'حادث تصادم بسيط، المسار الأيسر متوقف قرب تقاطع عينكاوة',
        latitude: 36.2167,
        longitude: 44.0089,
        roadName: 'شارع 100 متري - أربيل',
        roadSegmentId: 'erbil-100m',
        confidence: 0.88,
        confirmationsCount: 6,
        rejectionsCount: 0,
        status: 'CONFIRMED',
        expiresAt: DateTime.now().add(const Duration(minutes: 35)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        distanceMeters: 1400,
      ),
      RoadReportModel(
        id: 'rep-3',
        type: 'CHECKPOINT',
        title: 'نقطة تفتيش نشطة (سيطرة شيراوة)',
        description: 'إجراءات تدقيق هويات سلسة وتأخير لا يتجاوز 5 دقائق',
        latitude: 35.8500,
        longitude: 44.3833,
        roadName: 'طريق كركوك - أربيل',
        roadSegmentId: 'kirkuk-erbil-rd',
        confidence: 0.95,
        confirmationsCount: 12,
        rejectionsCount: 0,
        status: 'CONFIRMED',
        expiresAt: DateTime.now().add(const Duration(minutes: 45)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        distanceMeters: 8500,
      ),
      RoadReportModel(
        id: 'rep-4',
        type: 'POTHOLE',
        title: 'حفرة وتخسف مفاجئ في الطريق السريع',
        description: 'حفرة عميقة في المسار الأيمن بعد الجسر بـ 500 متر',
        latitude: 36.2000,
        longitude: 44.0300,
        roadName: 'طريق المطار السريع',
        roadSegmentId: 'erbil-airport',
        confidence: 0.85,
        confirmationsCount: 5,
        rejectionsCount: 0,
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 10)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        distanceMeters: 4100,
      ),
    ];
  }

  List<RoadQuestionModel> _getMockRoadQuestions() {
    return [
      RoadQuestionModel(
        id: 'nidaa-1',
        requesterUserId: 'user-2',
        questionType: 'TRAFFIC',
        title: 'هل هنالك زحمة؟',
        latitude: 36.2300,
        longitude: 43.8500,
        bearing: 310,
        roadName: 'طريق أربيل - دهوك M10',
        answersYes: 8,
        answersNo: 1,
        answersNotSure: 1,
        totalAnswers: 10,
        isAggregated: true,
        aggregatedSummary: '🔴 زحمة محتملة أمامك (8 من 10 سواق أكدوا وجودها)',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        distanceMeters: 2500,
      ),
      RoadQuestionModel(
        id: 'nidaa-2',
        requesterUserId: 'user-3',
        questionType: 'CHECKPOINT',
        title: 'هل توجد سيطرة / تفتيش؟',
        latitude: 36.2050,
        longitude: 44.0100,
        bearing: 270,
        roadName: 'شارع 100 متري',
        answersYes: 4,
        answersNo: 0,
        answersNotSure: 0,
        totalAnswers: 4,
        isAggregated: true,
        aggregatedSummary: '👮 سيطرة نشطة ومؤكدة من 4 سواق',
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        distanceMeters: 1200,
      ),
    ];
  }

  List<FuelStationModel> _getMockFuelStations() {
    return [
      FuelStationModel(
        id: 'fuel-1',
        nameAr: 'محطة وقود كوردستان 100 متري',
        nameEn: 'Kurdistan 100m Station',
        latitude: 36.2056,
        longitude: 44.0150,
        city: 'أربيل',
        address: 'شارع 100 متري قرب تقاطع عينكاوة',
        phone: '+9647501239991',
        petrolPrice: 850,
        premiumPrice: 1150,
        dieselPrice: 750,
        isPetrolAvailable: true,
        crowdLevel: 'LOW',
        rating: 4.6,
        isVerified: true,
        priceUpdatedAt: DateTime.now().subtract(const Duration(minutes: 35)),
        priceSource: 'COMMUNITY',
        distanceKm: 1.4,
      ),
      FuelStationModel(
        id: 'fuel-2',
        nameAr: 'محطة بيترول أوفيسي (طريق دهوك)',
        nameEn: 'Petrol Ofisi - Duhok Road',
        latitude: 36.3120,
        longitude: 43.6800,
        city: 'طريق دهوك السريع M10',
        address: 'طريق أربيل - دهوك السريع',
        phone: '+9647504443322',
        petrolPrice: 950,
        premiumPrice: 1250,
        dieselPrice: 800,
        isPetrolAvailable: true,
        crowdLevel: 'MEDIUM',
        rating: 4.8,
        isVerified: true,
        priceUpdatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        priceSource: 'OFFICIAL_OWNER',
        distanceKm: 4.8,
      ),
      FuelStationModel(
        id: 'fuel-3',
        nameAr: 'محطة وقود اليرموك الحكومية',
        nameEn: 'Al-Yarmouk Station',
        latitude: 33.3050,
        longitude: 44.3520,
        city: 'بغداد',
        address: 'جانب الكرخ - ساحة اليرموك',
        phone: '+9647801122334',
        petrolPrice: 450,
        premiumPrice: 850,
        dieselPrice: 400,
        isPetrolAvailable: true,
        crowdLevel: 'HIGH',
        rating: 4.2,
        isVerified: true,
        priceUpdatedAt: DateTime.now().subtract(const Duration(minutes: 50)),
        priceSource: 'USER_REPORT',
        distanceKm: 8.2,
      ),
    ];
  }

  List<PlaceModel> _getMockPlaces() {
    return [
      PlaceModel(
        id: 'p-1',
        categoryKey: 'tire_repair',
        nameAr: 'بنجرجي وتصليح إطارات السريع',
        nameEn: 'Express Tire Repair',
        latitude: 36.1980,
        longitude: 44.0120,
        address: 'أربيل - شارع 60 متري قرب تقاطع الشورجة',
        phone: '+9647509871122',
        openingHours: 'مفتوح 24 ساعة',
        rating: 4.8,
        reviewsCount: 34,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=600'],
        distanceKm: 1.2,
      ),
      PlaceModel(
        id: 'p-2',
        categoryKey: 'towing',
        nameAr: 'سطحة كوردستان للإنقاذ السريع',
        nameEn: 'Kurdistan Fast Towing',
        latitude: 36.2100,
        longitude: 44.0200,
        address: 'تغطية كاملة لطرق أربيل - دهوك - السليمانية',
        phone: '+9647501112233',
        openingHours: 'طوارئ 24/7',
        rating: 4.9,
        reviewsCount: 68,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600'],
        distanceKm: 2.5,
      ),
      PlaceModel(
        id: 'p-3',
        categoryKey: 'mechanic',
        nameAr: 'المركز الألماني لصيانة السيارات',
        nameEn: 'German Auto Care Center',
        latitude: 36.1850,
        longitude: 44.0300,
        address: 'أربيل - المنطقة الصناعية الجنوبية',
        phone: '+9647505557788',
        openingHours: '08:00 ص - 08:00 م',
        rating: 4.7,
        reviewsCount: 52,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=600'],
        distanceKm: 3.8,
      ),
    ];
  }

  Map<String, dynamic> _getMockRouteCalculation(String destName) {
    return {
      'origin': {'lat': 36.1911, 'lng': 44.0091, 'name': 'موقعي الحالي (أربيل)'},
      'destination': {'lat': 36.8679, 'lng': 42.9904, 'name': destName},
      'routes': [
        {
          'id': 'route-a',
          'name': 'طريق أربيل - دهوك السريع M10',
          'isRecommended': true,
          'distanceKm': 155.0,
          'durationMinutes': 138,
          'durationFormatted': '2 ساعة و 18 دقيقة',
          'eta': '06:35 م',
          'qualityScore': 92,
          'recommendationReason': 'أسرع بـ 13 دقيقة بسبب انخفاض الزحام وسلاسة السيطرات',
          'trafficCondition': 'LIGHT_TO_MODERATE',
          'incidentsSummary': {
            'totalIncidents': 2,
            'confirmedCount': 8,
            'warnings': [
              '🚦 زحمة بعد 3 كم (أكدها 8 سواق)',
              '⚠️ حادث بعد 6 كم تم تجاوزه للمسار الجانبي',
              '👮 نقطة تفتيش نشطة تم الإبلاغ عنها',
              '⛽ محطة بيترول أوفيسي بعد 4 كم (آخر تحديث للسعر قبل 35 دقيقة)',
            ]
          }
        },
        {
          'id': 'route-b',
          'name': 'طريق شيخان - القوش البديل',
          'isRecommended': false,
          'distanceKm': 161.0,
          'durationMinutes': 151,
          'durationFormatted': '2 ساعة و 31 دقيقة',
          'eta': '06:48 م',
          'qualityScore': 78,
          'recommendationReason': 'أطول بـ 6 كم وتوجد أعمال طريق قرب شيخان',
          'trafficCondition': 'MODERATE',
          'incidentsSummary': {
            'totalIncidents': 1,
            'confirmedCount': 3,
            'warnings': ['🚧 أعمال صيانة طريق في المسار الفرعي']
          }
        }
      ]
    };
  }
}
