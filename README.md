# دَرْب — DARB 🇮🇶
> **الشعار:** «اعرف الطريق قبل لا تمشيه.»  
> **المنظومة الذكية المتكاملة لبيانات الطرق الحية، مجتمع السائقين، وملاحة الواقع العراقي.**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-10.x-E0234E?logo=nestjs&logoColor=white)](https://nestjs.com)
[![PostgreSQL PostGIS](https://img.shields.io/badge/PostGIS-Spatial-336791?logo=postgresql&logoColor=white)](https://postgis.net)
[![Vector Tiles](https://img.shields.io/badge/Vector_Tiles-OpenFreeMap-10B981)](https://openfreemap.org)
[![Performance](https://img.shields.io/badge/FPS-60_Fluid-success)](docs/DEVELOPER_AND_ARCHITECTURE_GUIDE.md)

---

## 📚 الدلائل والتوثيق الشامل (Documentation & Guides)
- 📖 [**دليل الاستخدام الشامل للمستخدم العادي (User Guide)**](docs/USER_GUIDE.md): شرح كامل لجميع ميزات التطبيق (الخريطة، الملاحة التتبعية، البلاغات الـ 11، نداء الطريق، محطات الوقود، خدمات الطوارئ، وكراج السيارات).
- 🛠️ [**دليل الهندسة المعمارية والتشغيل (Developer & Architecture Guide)**](docs/DEVELOPER_AND_ARCHITECTURE_GUIDE.md): تفاصيل معمارية الخرائط الفيكتورية، محرك الـ 60 FPS، التخزين المؤقت، كبح التزاحم، إعداد السيرفر وقواعد البيانات، وبناء حزم Android و iOS.

---

## 🌟 أبرز ميزات المنظومة (Core Highlights)

1. **🗺️ خريطة فيكتور متقدمة بنمط Waze التبايني (Vector Tiles Engine):**
   - تم استبدال الـ Raster Tiles القديمة بالكامل ببلاطات فيكتور نقية (OpenFreeMap Liberty) عبر ector_map_tiles 7.0.0.
   - شوارع صفراء شريانية وسريعة مع حدود عالية التباين، شوارع بيضاء ناصعة، ومسار أخضر زمردي نيون عالي التباين نهاري/ليلي.
   - دوران محمي ومستقر مع بوصلة دائرية هندسية تعيد توجيه الخريطة للشمال بنقرة واحدة.

2. **⚡ أداء فائق وسلاسة 60 إطاراً في الثانية (60 FPS Performance Pass):**
   - **Zero Full Map Rebuilds:** فك ارتباط بيانات التيليميتري عبر ValueNotifier مخصصة للموقع والسرعة والاتجاه والدقة.
   - عزل مؤشر السيارة وعدّاد السرعة بطبقات مستقلة RepaintBoundary تمنع إعادة بناء الخريطة نهائياً عند نبضات الـ GPS.
   - كاميرا ملاحة مستمرة مع نطاق ميت (Deadband: < 1m و < 0.05 zoom) ومعدل تحديث مقيد (30 Hz) للقضاء على أي رعشة أو بطء.

3. **🏎️ نظام أيقونات هندسي فيكتوري موحد (Unified Vector Iconography):**
   - نظام رسم فيكتوري نقي (CustomPainter) بسرعة عرض 0ms بدون صور نقطية.
   - سهم مركبة شبحي انسيابي (Stealth Arrow) يضمن تبايناً 100% فوق كل ألوان الشوارع مع خط اتجاه ناصع.
   - 40+ أيقونة متخصصة تشمل جميع بلاغات الطريق ومحطات الوقود وخدمات الطوارئ.

4. **📡 نداء الطريق (Road Call — الاستفسار الذكي):**
   - ميزة فريدة لتوجيه أسئلة مسبقة للسائقين المتواجدين أمامك على مسار السير (1-10 كم) بنقرة واحدة وتجميع النتائج آلياً مع حماية الخصوصية 100%.

5. **⛽ شبكة محطات الوقود والأسعار الحية:**
   - استعراض أسعار البنزين العادي، المحسن، السوبر، والديزل بالدينار العراقي، مع تحديث تشاركي لحالة الازدحام على المضخات.

6. **🆘 دليل طوارئ وإنقاذ السيارات:**
   - اتصال فوري بالسطحات، بنجرجي متنقل، شحن البطارية، وورش الصيانة القريبة.

---

## 🏗️ البنية الهيكلية للمشروع (Monorepo Architecture)

`	ext
darab/
├── docs/                            # أدلة الاستخدام والتوثيق المعماري
│   ├── USER_GUIDE.md                # دليل المستخدم وسائق المركبة
│   └── DEVELOPER_AND_ARCHITECTURE_GUIDE.md # دليل المطورين والتشغيل
├── apps/
│   ├── backend/                     # NestJS / TypeScript Backend
│   │   ├── src/
│   │   │   ├── modules/
│   │   │   │   ├── auth/            # Phone OTP & JWT Auth
│   │   │   │   ├── users/           # Profile, Reputation, Garage/Vehicles
│   │   │   │   ├── reports/         # Live Incident Reports & Confidence Decay
│   │   │   │   ├── road-call/       # نداء الطريق (Spatial Targeted Dispatch)
│   │   │   │   ├── fuel/            # Fuel Stations & Live Crowdsourcing
│   │   │   │   ├── navigation/      # Route Quality & Delay Scorer
│   │   │   │   ├── places/          # Places Directory & Emergency Services
│   │   │   │   ├── trips/           # Trip Summary & Speed Anomaly Filter
│   │   │   │   ├── gamification/    # Badges & Leaderboard
│   │   │   │   └── realtime/        # WebSockets Gateway
│   │   │   └── main.ts              # Swagger Docs & Bootstrap
│   │   └── package.json
│   │
│   └── mobile/                      # Flutter Application (iOS & Android)
│       ├── lib/
│       │   ├── core/
│       │   │   ├── constants/       # Iraqi Cities, Highways, Questions
│       │   │   ├── theme/           # DarbIcons, Vector Theme, Dark/Light Themes
│       │   │   ├── services/        # DarbTileCache, DarbTilePrefetcher, ApiService
│       │   │   └── providers/       # AppState (Telemetry ValueNotifiers)
│       │   ├── features/
│       │   │   ├── home/            # Map Canvas (Isolated decoupled layers)
│       │   │   ├── navigation/      # Persistent Camera Follower HUD (60 FPS)
│       │   │   ├── road_reports/    # 1-Tap Incidents & Voting
│       │   │   ├── nidaa_al_tariq/  # نداء الطريق UI & Aggregated Polls
│       │   │   ├── fuel/            # Fuel Stations & Live Prices
│       │   │   ├── emergency/       # Towing, Tire, Battery, Mechanics
│       │   │   ├── places/          # Places Directory
│       │   │   └── trips/           # Trip Summary & Replay
│       │   └── main.dart
│       └── pubspec.yaml
│
└── docker/
    ├── docker-compose.yml           # PostgreSQL + PostGIS, Redis
    └── postgis-init.sql             # Spatial schema, triggers & initial seeds
`

---

## 🚀 البدء السريع والتشغيل المحلي (Quick Start)

### 1. تشغيل قاعدة البيانات PostGIS و Redis عبر Docker:
`ash
cd docker
docker-compose up -d
`

### 2. تشغيل الخادم الخلفي (NestJS Backend):
`ash
cd apps/backend
npm install
npm run build
npm run start:dev
`
- الـ API سيعمل على: http://localhost:4000/api/v1
- توثيق Swagger التفاعلي متاح على: http://localhost:4000/docs

### 3. تشغيل تطبيق الموبايل (Flutter App):
`ash
cd apps/mobile
flutter pub get
flutter run
`

---

## 📦 بناء حزم الإنتاج (Production Builds)

### Android (APK / App Bundle)
`ash
cd apps/mobile
flutter build apk --release
`

### iOS (Archive / IPA)
`ash
cd apps/mobile
flutter build ipa --no-codesign --release
`

> [!NOTE]
> الكود متوافق كلياً مع Flutter 3.24.x على بيئات بناء الـ CI (يستخدم Color.withOpacity() بدلاً من withValues())، مع الحفاظ على قفل حزمة intl: 0.19.0 في pubspec.lock.

---

## 🛡️ الأمان والخصوصية (Privacy & Safety)
- **Zero Exact Location Leaks:** لا يتم أبداً بث الموقع الدقيق لأي سائق للآخرين، ويتم استخدام معرفات مجهولة (Anonymous Handles) ونطاقات مكانية تقريبية.
- **Driver-Safe UI:** عناصر تفاعلية ضخمة لا تتطلب الكتابة أثناء القيادة، مع دعم كامل للوضع الليلي عالي التباين والتوجيهات الصوتية.
- **Offline Resilience:** تخزين محلي آمن للبلاغات دون إنترنت وإعادة إرسالها فور عودة التغطية.
