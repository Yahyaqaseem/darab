import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;
  String _baseUrl = AppConstants.defaultApiUrl;

  String get baseUrl => _baseUrl;

  ApiService({String? baseUrl}) {
    _baseUrl = baseUrl ?? AppConstants.defaultApiUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[API REQUEST] ${options.method} ${options.uri}');
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API RESPONSE] ${response.statusCode} from ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('[API ERROR] ${e.response?.statusCode} from ${e.requestOptions.uri} - ${e.message}');
          return handler.next(e);
        }
      ),
    );
  }

  Future<void> initSession() async {
    debugPrint('[AUTH] Initializing session from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('jwt_token');
    debugPrint('[AUTH] Session token loaded: ${_authToken != null ? "YES" : "NO"}');
  }

  Future<void> setAuthToken(String token) async {
    debugPrint('[AUTH] Saving new JWT token to secure storage/prefs...');
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    debugPrint('[AUTH] Token successfully saved.');
  }
  
  Future<void> clearAuthToken() async {
    debugPrint('[AUTH] Clearing auth token...');
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  bool get hasToken => _authToken != null;

  // --- Auth ---
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    debugPrint('[AUTH] Requesting OTP for phone: $phoneNumber');
    final res = await _dio.post('/auth/request-otp', data: {'phoneNumber': phoneNumber});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {String? username}) async {
    debugPrint('[AUTH] Verifying OTP...');
    final res = await _dio.post('/auth/verify-otp', data: {
      'phoneNumber': phoneNumber,
      'otp': otp,
      'username': username,
    });
    if (res.data['accessToken'] != null) {
      await setAuthToken(res.data['accessToken']);
    }
    return res.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    debugPrint('[AUTH] Fetching user profile...');
    final res = await _dio.get('/users/me');
    debugPrint('[AUTH] Profile fetched successfully.');
    return res.data;
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
      if (userLat != null) 'userLat': userLat,
      if (userLng != null) 'userLng': userLng,
    });
    return true;
  }

  // --- Live Questions ---
  Future<List<RoadQuestionModel>> getActiveRoadQuestions({double lat = 36.1911, double lng = 44.0091}) async {
    final res = await _dio.get('/road-questions/nearby', queryParameters: {'lat': lat, 'lng': lng});
    final list = res.data as List;
    return list.map((e) => RoadQuestionModel.fromJson(e)).toList();
  }

  Future<RoadQuestionModel> askRoadQuestion(Map<String, dynamic> data) async {
    final res = await _dio.post('/road-call/ask', data: data);
    return RoadQuestionModel.fromJson(res.data);
  }

  Future<bool> answerRoadQuestion(String questionId, String answer, {double? userLat, double? userLng}) async {
    await _dio.post('/road-call/$questionId/answer', data: {
      'answer': answer,
      if (userLat != null) 'userLat': userLat,
      if (userLng != null) 'userLng': userLng,
    });
    return true;
  }

  // --- Places & Fuel ---
  Future<List<FuelStationModel>> getNearbyFuelStations({double lat = 36.1911, double lng = 44.0091}) async {
    final res = await _dio.get('/fuel/nearby', queryParameters: {'lat': lat, 'lng': lng});
    final list = res.data as List;
    return list.map((e) => FuelStationModel.fromJson(e)).toList();
  }

  Future<bool> updateFuelReport(String stationId, Map<String, dynamic> data) async {
    await _dio.post('/fuel/$stationId/report', data: data);
    return true;
  }

  Future<List<PlaceModel>> getNearbyPlaces({double lat = 36.1911, double lng = 44.0091, String? category}) async {
    final res = await _dio.get('/places/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      if (category != null) 'category': category,
    });
    final list = res.data as List;
    return list.map((e) => PlaceModel.fromJson(e)).toList();
  }

  // --- Navigation Route ---
  Future<Map<String, dynamic>> calculateRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originName,
    String? destName,
  }) async {
    final res = await _dio.post('/navigation/calculate-routes', data: {
      'originLat': originLat,
      'originLng': originLng,
      'destLat': destLat,
      'destLng': destLng,
      'originName': originName,
      'destName': destName,
    });
    return res.data;
  }
}
