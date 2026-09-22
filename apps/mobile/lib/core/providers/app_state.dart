import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/api_service.dart';

enum TripState { IDLE, DESTINATION_SELECTED, ROUTE_PREVIEW, NAVIGATING, ARRIVING, COMPLETED, CANCELLED }

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription<Position>? _positionStream;

  // Theme & Locale
  bool _isDarkMode = true;
  String _currentLanguage = 'ar';

  // Auth & Profile
  bool _isAuthenticated = false;
  String _driverUsername = 'سائق_درب';
  String _trustLevel = 'BEGINNER';
  int _reputationScore = 0;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _badges = [];

  // Map & Location
  double _currentLat = 36.191113; // Erbil
  double _currentLng = 44.009167;
  String _currentCity = 'أربيل';
  double _currentSpeedKmh = 0.0;
  List<double> _speedBuffer = [65, 70, 72, 75, 78];

  // Navigation State
  TripState _tripState = TripState.IDLE;
  Map<String, dynamic>? _activeRoute;
  String? _destinationName;
  double? _destLat;
  double? _destLng;

  // Live Road Data
  List<RoadReportModel> _reports = [];
  List<RoadQuestionModel> _activeRoadQuestions = [];
  List<FuelStationModel> _fuelStations = [];
  List<PlaceModel> _places = [];
  bool _isLoading = false;

  // Offline Resilience Outbox Queue
  final List<Map<String, dynamic>> _offlineReportsQueue = [];
  final List<Map<String, dynamic>> _offlineAnswersQueue = [];
  bool _isOffline = false;

  // Navigation Reroute Debounce Timer
  DateTime? _lastRerouteCalculation;

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  bool get isAuthenticated => _isAuthenticated;
  String get driverUsername => _driverUsername;
  String get trustLevel => _trustLevel;
  int get reputationScore => _reputationScore;
  List<Map<String, dynamic>> get vehicles => _vehicles;
  List<Map<String, dynamic>> get badges => _badges;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  String get currentCity => _currentCity;
  double get currentSpeedKmh => _currentSpeedKmh;
  TripState get tripState => _tripState;
  Map<String, dynamic>? get activeRoute => _activeRoute;
  String? get destinationName => _destinationName;
  List<RoadReportModel> get reports => _reports;
  List<RoadQuestionModel> get activeRoadQuestions => _activeRoadQuestions;
  List<FuelStationModel> get fuelStations => _fuelStations;
  List<PlaceModel> get places => _places;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  int get offlinePendingCount => _offlineReportsQueue.length + _offlineAnswersQueue.length;
  ApiService get apiService => _apiService;

  Timer? _flushTimer;
  bool _isDisposed = false;

  AppState() {
    // Delay loadInitialData until after the first frame to avoid notifyListeners during build
    Future.microtask(() => loadInitialData());
    // Background queue flush check
    _flushTimer = Timer.periodic(const Duration(seconds: 15), (_) => flushOfflineQueue());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _flushTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  void updateLocation(double lat, double lng, String city) {
    _currentLat = lat;
    _currentLng = lng;
    _currentCity = city;
    notifyListeners();
    loadNearbyData();

    // Reroute Debouncing: check if navigating and needs recalibration (min 10s gap)
    if (_tripState == TripState.NAVIGATING && _destLat != null && _destLng != null) {
      final dist = const Distance().as(LengthUnit.Meter, LatLng(lat, lng), LatLng(_destLat!, _destLng!));
      if (dist < 100) {
        _tripState = TripState.ARRIVING;
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          _tripState = TripState.COMPLETED;
          notifyListeners();
        });
      } else {
        final now = DateTime.now();
        if (_lastRerouteCalculation == null || now.difference(_lastRerouteCalculation!).inSeconds > 10) {
          _lastRerouteCalculation = now;
          _recalculateActiveRoute();
        }
      }
    }
  }

  Future<void> startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[APP_STATE] Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[APP_STATE] Location permissions are denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[APP_STATE] Location permissions are permanently denied.');
      return;
    }

    // Get initial location
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      updateLocation(position.latitude, position.longitude, 'موقعي الحالي');
    } catch (e) {
      debugPrint('[APP_STATE] Error getting initial location: $e');
    }

    // Start stream
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      // Calculate speed: position.speed is in m/s, convert to km/h
      double speedKmh = position.speed * 3.6;
      if (speedKmh < 0) speedKmh = 0;
      // Filter out crazy spikes (> 200 km/h) unless they are consistent, but for now just cap/filter:
      if (speedKmh > 200.0) speedKmh = 0; // Likely a GPS anomaly
      
      _currentSpeedKmh = speedKmh;
      updateLocation(position.latitude, position.longitude, 'موقعي الحالي');
    });
  }

  Future<void> _recalculateActiveRoute() async {
    if (_destLat == null || _destLng == null) return;
    try {
      final res = await _apiService.calculateRoutes(
        originLat: _currentLat,
        originLng: _currentLng,
        destLat: _destLat!,
        destLng: _destLng!,
        originName: 'موقعي الحالي',
        destName: _destinationName,
      );
      if (res['routes'] != null && (res['routes'] as List).isNotEmpty) {
        _activeRoute = res['routes'][0];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Reroute recalculation skipped: $e');
    }
  }

  Future<void> loadInitialData() async {
    debugPrint('[APP_STATE] Starting loadInitialData()');
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.initSession();
      if (!_apiService.hasToken) {
        debugPrint('[APP_STATE] No valid session found. Forcing LoginScreen.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('[APP_STATE] Session found. Attempting to load profile...');
      final profile = await _apiService.getProfile();
      if (profile['user'] != null) {
        _driverUsername = profile['user']['username'] ?? _driverUsername;
        _trustLevel = profile['user']['trustLevel'] ?? _trustLevel;
        _reputationScore = profile['user']['reputationScore'] ?? _reputationScore;
      }
      _vehicles = (profile['vehicles'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _badges = (profile['badges'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

      _isOffline = false;
      _isAuthenticated = true;
      debugPrint('[APP_STATE] Authentication successful! Navigating to HomeScreen.');
      await startLocationTracking();
      await loadNearbyData();
    } catch (e) {
      debugPrint('[APP_STATE] Exception during loadInitialData: $e');
      if (_apiService.hasToken) {
        debugPrint('[APP_STATE] User has token but network failed. Activating Offline Resilience Mode.');
        _isOffline = true;
        _isAuthenticated = true;
        await startLocationTracking(); // Try getting location offline anyway
      } else {
        debugPrint('[APP_STATE] Auth failed. Retaining LoginScreen.');
        _isAuthenticated = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyData() async {
    try {
      _reports = await _apiService.getNearbyReports(lat: _currentLat, lng: _currentLng);
      _activeRoadQuestions = await _apiService.getActiveRoadQuestions(lat: _currentLat, lng: _currentLng);
      _fuelStations = await _apiService.getNearbyFuelStations(lat: _currentLat, lng: _currentLng);
      _places = await _apiService.getNearbyPlaces(lat: _currentLat, lng: _currentLng);
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      debugPrint('Error loading nearby data (offline active): $e');
    }
    notifyListeners();
  }

  // Submit Fast 1-Tap Road Report with Offline Queue
  Future<void> submitReport(String type, {String? description, String? roadName}) async {
    final reportPayload = {
      'type': type,
      'latitude': _currentLat,
      'longitude': _currentLng,
      'roadName': roadName ?? 'طريق $_currentCity السريع',
      'description': description ?? '',
    };

    try {
      final created = await _apiService.createReport(reportPayload);
      _reports.insert(0, created);
      _reputationScore += 10; // +10 points
      _isOffline = false;
    } catch (e) {
      // Offline fallback: enqueue for automatic background sync
      _offlineReportsQueue.add(reportPayload);
      _isOffline = true;
      _reports.insert(
        0,
        RoadReportModel(
          id: 'offline-rep-${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          title: 'بلاغ قيد الإرسال (دون اتصال)',
          description: description ?? '',
          latitude: _currentLat,
          longitude: _currentLng,
          roadName: roadName ?? 'طريق $_currentCity السريع',
          roadSegmentId: 'offline-segment',
          confidence: 0.6,
          confirmationsCount: 1,
          rejectionsCount: 0,
          status: 'ACTIVE',
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
          distanceMeters: 0,
        ),
      );
    }
    notifyListeners();
  }

  // Confirm or Dispute Report
  Future<void> confirmReport(String reportId, String vote) async {
    try {
      await _apiService.confirmReport(reportId, vote);
    } catch (e) {
      _offlineAnswersQueue.add({'action': 'confirmReport', 'reportId': reportId, 'vote': vote});
    }

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final old = _reports[index];
      if (vote == 'CONFIRM') {
        _reports[index] = RoadReportModel(
          id: old.id,
          type: old.type,
          title: old.title,
          description: old.description,
          latitude: old.latitude,
          longitude: old.longitude,
          roadName: old.roadName,
          roadSegmentId: old.roadSegmentId,
          bearing: old.bearing,
          confidence: (old.confidence + 0.12).clamp(0.0, 0.99),
          confirmationsCount: old.confirmationsCount + 1,
          rejectionsCount: old.rejectionsCount,
          status: 'CONFIRMED',
          expiresAt: old.expiresAt,
          createdAt: old.createdAt,
          distanceMeters: old.distanceMeters,
        );
        _reputationScore += 3; // +3 points
      }
      notifyListeners();
    }
  }

  // Ask Road Call (نداء الطريق)
  Future<void> askRoadQuestion(String type, {String? customText}) async {
    final questionPayload = {
      'questionType': type,
      'latitude': _currentLat,
      'longitude': _currentLng,
      'roadName': 'طريق $_currentCity - دهوك M10',
      'customText': customText,
    };

    try {
      final created = await _apiService.askRoadQuestion(questionPayload);
      _activeRoadQuestions.insert(0, created);
    } catch (e) {
      _offlineAnswersQueue.add({'action': 'askRoadQuestion', 'payload': questionPayload});
    }
    notifyListeners();
  }

  // Answer Road Call
  Future<void> answerRoadQuestion(String questionId, String answer) async {
    try {
      await _apiService.answerRoadQuestion(questionId, answer);
    } catch (e) {
      _offlineAnswersQueue.add({'action': 'answerRoadQuestion', 'questionId': questionId, 'answer': answer});
    }

    final idx = _activeRoadQuestions.indexWhere((q) => q.id == questionId);
    if (idx != -1) {
      final old = _activeRoadQuestions[idx];
      _activeRoadQuestions[idx] = RoadQuestionModel(
        id: old.id,
        requesterUserId: old.requesterUserId,
        questionType: old.questionType,
        title: old.title,
        customText: old.customText,
        latitude: old.latitude,
        longitude: old.longitude,
        bearing: old.bearing,
        roadName: old.roadName,
        answersYes: answer.contains('نعم') || answer == 'YES' ? old.answersYes + 1 : old.answersYes,
        answersNo: answer.contains('لا') || answer == 'NO' ? old.answersNo + 1 : old.answersNo,
        answersNotSure: answer.contains('غير') || answer == 'NOT_SURE' ? old.answersNotSure + 1 : old.answersNotSure,
        totalAnswers: old.totalAnswers + 1,
        isAggregated: true,
        aggregatedSummary: '🔴 تم تأكيد المعلومة من السائقين',
        expiresAt: old.expiresAt,
        createdAt: old.createdAt,
      );
      _reputationScore += 2; // +2 points
      notifyListeners();
    }
  }

  // Flush Pending Outbox Queue upon Reconnection
  Future<void> flushOfflineQueue() async {
    if (_offlineReportsQueue.isEmpty && _offlineAnswersQueue.isEmpty) return;

    final reportsToSend = List<Map<String, dynamic>>.from(_offlineReportsQueue);
    for (final item in reportsToSend) {
      try {
        await _apiService.createReport(item);
        _offlineReportsQueue.remove(item);
      } catch (_) {
        break; // Network still unavailable
      }
    }

    final answersToSend = List<Map<String, dynamic>>.from(_offlineAnswersQueue);
    for (final item in answersToSend) {
      try {
        if (item['action'] == 'answerRoadQuestion') {
          await _apiService.answerRoadQuestion(item['questionId'], item['answer']);
        } else if (item['action'] == 'confirmReport') {
          await _apiService.confirmReport(item['reportId'], item['vote']);
        }
        _offlineAnswersQueue.remove(item);
      } catch (_) {
        break;
      }
    }

    notifyListeners();
  }

  // Update Fuel Report
  Future<void> updateFuelStation(String stationId, {int? petrolPrice, int? premiumPrice, bool? isAvailable, String? crowdLevel}) async {
    await _apiService.updateFuelReport(stationId, {
      'petrolPrice': petrolPrice,
      'premiumPrice': premiumPrice,
      'isAvailable': isAvailable,
      'crowdLevel': crowdLevel,
    });
    _reputationScore += 5; // +5 points
    await loadNearbyData();
  }

  // Start Driving Navigation HUD
  void selectRoutePreview(Map<String, dynamic> route, String destName, double destLat, double destLng) {
    _activeRoute = route;
    _destinationName = destName;
    _destLat = destLat;
    _destLng = destLng;
    _tripState = TripState.ROUTE_PREVIEW;
    notifyListeners();
  }

  void startNavigation() {
    _tripState = TripState.NAVIGATING;
    notifyListeners();
  }

  void setTripState(TripState state) {
    _tripState = state;
    notifyListeners();
  }

  void stopNavigation() {
    _tripState = TripState.IDLE;
    _activeRoute = null;
    _destinationName = null;
    _destLat = null;
    _destLng = null;
    notifyListeners();
  }
}


