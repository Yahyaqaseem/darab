import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'دَرْب — DARB';
  static const String appSlogan = 'اعرف الطريق قبل لا تمشيه.';
  static const String defaultApiUrl = 'http://localhost:4000/api/v1';

  // Major Iraqi Cities & Coordinates
  static const Map<String, Map<String, dynamic>> iraqiCities = {
    'erbil': {'name': 'أربيل', 'lat': 36.191113, 'lng': 44.009167},
    'duhok': {'name': 'دهوك', 'lat': 36.8679, 'lng': 42.9904},
    'sulaymaniyah': {'name': 'السليمانية', 'lat': 35.5558, 'lng': 45.4351},
    'baghdad': {'name': 'بغداد', 'lat': 33.3152, 'lng': 44.3661},
    'kirkuk': {'name': 'كركوك', 'lat': 35.4681, 'lng': 44.3922},
    'mosul': {'name': 'الموصل', 'lat': 36.3400, 'lng': 43.1300},
    'basra': {'name': 'البصرة', 'lat': 30.5081, 'lng': 47.7835},
    'najaf': {'name': 'النجف الأشرف', 'lat': 32.0259, 'lng': 44.3463},
    'karbala': {'name': 'كربلاء المقدسة', 'lat': 32.6160, 'lng': 44.0249},
  };

  // Road Report Item Definitions
  static const List<Map<String, dynamic>> reportTypes = [
    {
      'type': 'ACCIDENT',
      'label': 'حادث سير',
      'icon': Icons.car_crash,
      'color': Color(0xFFEF4444),
      'desc': 'حادث أو اصطدام يعيق حركة السير',
    },
    {
      'type': 'HEAVY_TRAFFIC',
      'label': 'ازدحام مروري',
      'icon': Icons.traffic,
      'color': Color(0xFFF59E0B),
      'desc': 'توقف أو بطء شديد في حركة السير',
    },
    {
      'type': 'CHECKPOINT',
      'label': 'نقطة تفتيش',
      'icon': Icons.security,
      'color': Color(0xFF3B82F6),
      'desc': 'سيطرة أو نقطة تفتيش أمنية نشطة',
    },
    {
      'type': 'CLOSURE',
      'label': 'طريق مغلق',
      'icon': Icons.do_not_disturb_on,
      'color': Color(0xFFDC2626),
      'desc': 'إغلاق كلي للشارع أو تحويلة إجبارية',
    },
    {
      'type': 'POTHOLE',
      'label': 'حفرة / تخسف',
      'icon': Icons.warning_rounded,
      'color': Color(0xFFD97706),
      'desc': 'حفرة عميقة أو تلف في طبقة الإسفلت',
    },
    {
      'type': 'WATER_ACCUMULATION',
      'label': 'تجمع مياه',
      'icon': Icons.water_drop,
      'color': Color(0xFF06B6D4),
      'desc': 'تجمع مياه أمطار أو طفح يعيق العبور',
    },
    {
      'type': 'DETOUR',
      'label': 'تحويلة',
      'icon': Icons.alt_route,
      'color': Color(0xFF8B5CF6),
      'desc': 'تحويلة لمسار جانبي أو ترابي',
    },
    {
      'type': 'BROKEN_CAR',
      'label': 'سيارة معطلة',
      'icon': Icons.build_circle,
      'color': Color(0xFF64748B),
      'desc': 'مركبة متوقفة في جانب الطريق',
    },
  ];

  // Quick Questions for Road Call (نداء الطريق)
  static const List<Map<String, dynamic>> roadCallTemplates = [
    {
      'type': 'TRAFFIC',
      'title': 'هل هنالك زحمة؟',
      'icon': Icons.traffic,
      'options': ['نعم', 'لا', 'غير متأكد'],
    },
    {
      'type': 'ROAD_CONDITION',
      'title': 'كيف وضع الطريق؟',
      'icon': Icons.alt_route,
      'options': ['جيد وسالك', 'متوسط', 'سيئ ومزدحم'],
    },
    {
      'type': 'ACCIDENT',
      'title': 'هل يوجد حادث؟',
      'icon': Icons.car_crash,
      'options': ['نعم', 'لا', 'غير متأكد'],
    },
    {
      'type': 'CHECKPOINT',
      'title': 'هل توجد سيطرة / تفتيش؟',
      'icon': Icons.security,
      'options': ['نعم', 'لا', 'غير متأكد'],
    },
    {
      'type': 'FUEL_AVAILABILITY',
      'title': 'هل توجد محطة فيها بنزين؟',
      'icon': Icons.local_gas_station,
      'options': ['نعم متوفر', 'غير متوفر', 'غير متأكد'],
    },
    {
      'type': 'WATER_FLOOD',
      'title': 'هل يوجد تجمع مياه؟',
      'icon': Icons.water_drop,
      'options': ['نعم', 'لا'],
    },
  ];

  // Quick Action Chips on Home Screen
  static const List<Map<String, dynamic>> homeQuickActions = [
    {'key': 'nav', 'label': 'ابدأ رحلة', 'icon': Icons.navigation_rounded, 'color': Color(0xFF0A5C36)},
    {'key': 'fuel', 'label': 'بنزين', 'icon': Icons.local_gas_station_rounded, 'color': Color(0xFFF97316)},
    {'key': 'restaurant', 'label': 'مطاعم', 'icon': Icons.restaurant_rounded, 'color': Color(0xFF3B82F6)},
    {'key': 'mechanic', 'label': 'ورش', 'icon': Icons.build_rounded, 'color': Color(0xFF8B5CF6)},
    {'key': 'tire_repair', 'label': 'بنجرجي', 'icon': Icons.tire_repair, 'color': Color(0xFFEAB308)},
    {'key': 'car_wash', 'label': 'غسيل سيارات', 'icon': Icons.local_car_wash_rounded, 'color': Color(0xFF06B6D4)},
  ];
}
