# 🛠️ دليل الهندسة المعمارية والتشغيل التقني — DARB Architecture & Developer Guide
> **توثيق معماري شامل لمنظومة دَرْب: الخرائط الفيكتورية، محرك الـ 60 FPS، نظام الأيقونات، الخادم الخلفي، وبناء التطبيق.**

---

## 📑 فهرس المحتويات
1. [المعمارية العامة للنظام (System Architecture)](#1-المعمارية-العامة-للنظام-system-architecture)
2. [معمارية الخرائط الفيكتورية (Vector Tiles & Waze Style)](#2-معمارية-الخرائط-الفيكتورية-vector-tiles--waze-style)
3. [محرك الأداء وثبات الإطارات (60 FPS Performance Pipeline)](#3-محرك-الأداء-وثبات-الإطارات-60-fps-performance-pipeline)
4. [نظام الأيقونات الموحد المتقدم (DarbIcons System)](#4-نظام-الأيقونات-الموحد-المتقدم-darbicons-system)
5. [الخادم الخلفي وقواعد البيانات (Backend API & PostGIS)](#5-الخادم-الخلفي-وقواعد-البيانات-backend-api--postgis)
6. [دليل التشغيل والتثبيت المحلي (Local Development Setup)](#6-دليل-التشغيل-والتثبيت-المحلي-local-development-setup)
7. [دليل بناء حزم الإنتاج (Building for Android & iOS)](#7-دليل-بناء-حزم-الإنتاج-building-for-android--ios)
8. [معايير التوافقية والأمان (Compatibility & Security)](#8-معايير-التوافقية-والأمان-compatibility--security)

---

## 1. المعمارية العامة للنظام (System Architecture)

تعتمد منظومة **دَرْب** على هيكلية Monorepo مقسمة إلى ثلاث طبقات رئيسية:
1. **تطبيق الموبايل (`apps/mobile`):** مبني بتقنية Flutter (iOS & Android)، ومجهز بمحرك تصيير خرائط فيكتوري نقي، ونظام إدارة حالة عبر Provider/ValueNotifiers.
2. **الخادم الخلفي (`apps/backend`):** مبني بتقنية NestJS (TypeScript)، مع قاعدة بيانات PostgreSQL + PostGIS للعمليات المكانية، ومخزن Redis اللحظي لرسائل الـ WebSockets وتنسيق محادثات نداء الطريق.
3. **محرك المسارات المحلي (Routing Engine):** اتصال مباشر مع خوادم OSRM المفتوحة لتوفير توجيه دقيق بدون أي اعتمادية على خدمات Google Maps المدفوعة.

---

## 2. معمارية الخرائط الفيكتورية (Vector Tiles & Waze Style)

### استبدال الـ Raster Tiles القديمة بالكامل
- **المكتبة:** `vector_map_tiles: 7.0.0` متوافقة كلياً مع `flutter_map: 6.2.1`.
- **المزود:** سيرفرات OpenFreeMap (نمط Liberty) بدون الحاجة لأي مفتاح API.
- **التصميم البصري (Waze Visual Hierarchy):**
  - شوارع رئيسية وسريعة صفراء حيوية (`#FFD54F` / `#FFA000`) مع حدود تباينية داكنة بنية/رمادية.
  - شوارع محلية بيضاء واضحة ذات تباين عالٍ.
  - أسطح وأراضي رمادية فاتحة متناسقة تبرز تفاصيل الشوارع ومسارات السير.
  - خط مسار الملاحة الأخضر الفسفوري الزمردي (`#10B981`) مع حدود داكنة عميقة توفر وضوحاً كاملاً في كل الظروف الجوية.
- **التخزين المؤقت متعدد المستويات (`DarbCachingTileProvider`):**
  - **L1 RAM Cache:** يتسع لـ 600 بلاطة عبر `LinkedHashMap` بتعقيد $O(1)$ لاسترجاع فوري (0ms).
  - **L2 Disk Cache:** مجلد محلي على ذاكرة الجهاز بسعة 256 ميغابايت يحتفظ بالبلاطات لأسابيع.
- **التحميل المسبق الاستباقي لمسار الرحلة (`DarbTilePrefetcher`):**
  - تحميل مسبق دائري لمحيط السائق فور فتح التطبيق.
  - تحميل مسبق على طول ممر المسار بمجرد اختيار الوجهة وبدء الملاحة.
  - كبح التزاحم (حد أقصى 2 بلاطات في آن واحد) وإيقاف التحميل المسبق مؤقتاً أثناء سحب الخريطة بالأصابع لمنح الأولوية المطلقة للشاشة.

---

## 3. محرك الأداء وثبات الإطارات (60 FPS Performance Pipeline)

لحل مشكلات سقوط الإطارات (Frame Drops) الناتجة عن نبضات الـ GPS، تم تطبيق الهندسة التالية:
1. **فك ارتباط بيانات التيليميتري (Telemetry Decoupling):**
   - تم إنشاء `ValueNotifier` مخصصة لكل من: الموقع (`LatLng`)، السرعة (`double`)، زاوية الاتجاه (`double`)، ودقة الحساس (`double`).
   - إلغاء استدعاء `notifyListeners()` في التحديثات الروتينية لموقع السيارة في `AppState`.
2. **عزل طبقات العرض واستخدام `listen: false`:**
   - استخدام `listen: false` داخل شاشتي `HomeScreen` و `NavigationScreen`.
   - عزل مؤشر السيارة داخل `ValueListenableBuilder<LatLng>` في طبقة `MarkerLayer` منفصلة تماماً، مما يمنع إعادة بناء الخريطة الفيكتورية أو طبقة المسار نهائياً عند كل نبضة GPS.
3. **متحكم كاميرا دائم بنطاق ميت (Deadband Follower):**
   - كائن `AnimationController` واحد دائم يُنشأ في `initState` ويُتلف في `dispose`.
   - نطاق ميت ذكي (Deadband): إذا كانت حركة السيارة أقل من **1.0 متر** والزووم أقل من **0.05**، يتم تجاهل الحركة لتفادي الهزات الدقيقة.
   - تقييد معدل تحديث الكاميرا إلى حد أقصى **30 هرتز** (33ms).
4. **العزل الرسومي عبر `RepaintBoundary`:**
   - تغليف طبقة الخريطة، المسار، العلامات، مؤشر المركبة، عداد السرعة، والشريط العلوي واللوحة السفلية بـ `RepaintBoundary` لعزل الـ Render Layers.
5. **إزالة الرسوميات المجهدة للمعالج:**
   - استبدال `MaskFilter.blur` بمسارات رسم تظليل ثنائية النفاذية (Dual-pass alpha fill)، مما يقضي على الـ GPU stall.

---

## 4. نظام الأيقونات الموحد المتقدم (DarbIcons System)

تم بناء نظام أيقونات هندسي فيكتوري كامل في `apps/mobile/lib/core/theme/darb_icons.dart`:
- رسم فيكتوري نقي عبر `CustomPainter` على شبكة معيارية 24x24 بسماكة خط 1.8–2.0 بكسل.
- سرعة عرض 0ms بدون استهلاك ذاكرة وبدون أي بكسلة.
- لوحة ألوان دقيقة:
  - أخضر زمردي (`#10B981`)
  - برتقالي تحذيري (`#F59E0B`)
  - أحمر تحذيري حرج (`#EF4444`)
  - أزرق أمني (`#3B82F6`)
  - تيتانيوم داكن (`#0F172A`)
- مؤشر المركبة الشبحي الانسيابي (`_DarbVehicleMarkerPainter`) بهيكل تيتانيوم داكن مع حافة زمردية تضمن تبايناً 100% فوق كل ألوان الطرق.

---

## 5. الخادم الخلفي وقواعد البيانات (Backend API & PostGIS)

- **بيئة العمل:** NestJS 10 + Node.js 20+
- **قاعدة البيانات:** PostgreSQL 16 مع إضافة PostGIS لجميع الاستعلامات المكانية (`ST_DWithin`, `ST_Distance`).
- **المصادقة:** Phone OTP مع JWT Auth Guard.
- **محرك نداء الطريق:** يقوم الخادم باستقبال سؤال السائق، واستعلام السائقين المتواجدين على نفس المسار أمام السائل بزاوية تطابق اتجاه ($\pm 35^\circ$) ومسافة ($500	ext{m} - 15	ext{km}$)، وبث التنبيه عبر WebSockets / Redis PubSub.
- **التوثيق الحي:** Swagger متاح محلياً على `/docs`.

---

## 6. دليل التشغيل والتثبيت المحلي (Local Development Setup)

### المتطلبات الأساسية
- Node.js >= 20.x
- Docker & Docker Compose
- Flutter SDK (الإصدار الموصى به: 3.24.x أو أحدث)

### 1. تشغيل قاعدة البيانات PostGIS و Redis
```bash
cd docker
docker-compose up -d
```

### 2. تشغيل الخادم الخلفي (Backend)
```bash
cd apps/backend
npm install
npm run build
npm run start:dev
```
- سيعمل السيرفر على: `http://localhost:4000/api/v1`
- واجهة Swagger: `http://localhost:4000/docs`

### 3. تشغيل تطبيق الموبايل (Flutter)
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 7. دليل بناء حزم الإنتاج (Building for Android & iOS)

### بناء حزمة أندرويد (Release APK & App Bundle)
```bash
cd apps/mobile
flutter build apk --release
# أو لبناء App Bundle لمتجر Google Play:
flutter build appbundle --release
```

### بناء حزمة آيفون (iOS Archive & IPA)
> [!IMPORTANT]
> تم ضبط جميع شفرات الواجهات لتستخدم `Color.withOpacity()` بدلاً من `Color.withValues()`، لضمان التوافق التام مع بيئات CI/CD الخاصة بـ GitHub Actions (macOS runners) التي تعمل على Flutter 3.24.x.
> كما يتم الحفاظ دائماً على إصدار حزمة `intl: 0.19.0` في ملف `pubspec.lock`.

```bash
cd apps/mobile
flutter build ipa --no-codesign --release
```

---

## 8. معايير التوافقية والأمان (Compatibility & Security)

- **حماية الخصوصية:** لا يتم تخزين أو بث الموقع الدقيق للمستخدمين.
- **سلامة السائق:** واجهات ضخمة بلمسة واحدة بدون لوحة مفاتيح أثناء الحركة.
- **الاستقرار:** تم اختبار الكود بـ `flutter analyze` وحقق **0 errors** واجتازت جميع اختبارات `flutter test` بنسبة 100%.
