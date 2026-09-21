# دَرْب — DARB 🇮🇶
> **الشعار:** «اعرف الطريق قبل لا تمشيه.»  
> **المنظومة الذكية المتكاملة لبيانات الطرق الحية، مجتمع السائقين، وملاحة الواقع العراقي.**

---

## 🌟 فكرة المشروع ورؤيته (Product Vision)
**دَرْب (DARB)** ليس مجرد تطبيق خرائط تقليدي، بل هو منصة ذكاء طرقي محلية تجمع بين:
1. **Live Road Intelligence:** بلاغات الطرق الحية (حوادث، زحام، سيطرات أمنية، حفر، قطوعات، تجمعات مياه) بضغطة واحدة وبدون تعقيد أثناء القيادة.
2. **📡 نداء الطريق (Road Call):** ميزة حصرية تتيح للسائق توجيه أسئلة سريعة مسبقة الصنع للسائقين المتواجدين أمامه فعلياً على نفس مسار السير ($500\text{m} - 15\text{km}$) مع تجميع النتائج آلياً وحماية خصوصية المواقع.
3. **⛽ شبكة محطات الوقود والأسعار:** معرفة توفر البنزين العادي والمحسن والديزل بالدينار العراقي، مستوى الازدحام على المضخات، وتحديث الأسعار لحظياً من مجتمع السائقين.
4. **🧭 Smart Navigation & Route Quality:** اقتراح المسارات ومقارنتها بناءً على جودة الطريق ونقاط التفتيش والازدحامات وليس المسافة فقط.
5. **🚗 تصفية طفرات السرعة (Trusted Max Speed):** خوارزمية ذكية تلغي القراءات الشاذة الناتجة عن انعكاسات الـ GPS (مثل طفرة الـ 250 كم/س) واحتساب السرعة الموثوقة الحقيقية.
6. **🆘 أحتاج مساعدة (Emergency Car Services):** دليل فوري لطلب السطحات، بنجرجي متنقل، شحن البطاريات، وورش الصيانة.
7. **🏆 Gamification & Trust System:** نظام سمعة ونقاط مستويات وأوسمة («عين أربيل»، «خبير الطرق»، «ملك السفر»، «مستكشف العراق»).

---

## 🏗️ البنية الهيكلية للمشروع (Monorepo Architecture)

```text
darab/
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
│       │   │   ├── theme/           # Emerald, Sand, Dark/Light Themes
│       │   │   ├── models/          # Strongly typed domain models
│       │   │   ├── services/        # ApiService & Mock Resilience Layer
│       │   │   └── providers/       # Riverpod / AppState Controller
│       │   ├── features/
│       │   │   ├── home/            # Map Canvas, 1-Tap floating bar
│       │   │   ├── auth/            # Phone OTP & Username setup
│       │   │   ├── navigation/      # Turn-by-Turn HUD & Speedometer
│       │   │   ├── road_reports/    # 1-Tap Incidents & Voting
│       │   │   ├── nidaa_al_tariq/  # نداء الطريق UI & Aggregated Polls
│       │   │   ├── fuel/            # Fuel Stations & Live Prices
│       │   │   ├── emergency/       # Towing, Tire, Battery, Mechanics
│       │   │   ├── places/          # Places Directory
│       │   │   ├── trips/           # Trip Summary & Replay
│       │   │   └── profile/         # Garage, Badges, Reputation
│       │   └── main.dart
│       └── pubspec.yaml
│
└── docker/
    ├── docker-compose.yml           # PostgreSQL + PostGIS, Redis
    └── postgis-init.sql             # Spatial schema, triggers & initial seeds
```

---

## 🚀 تشغيل الخادم الخلفي (Backend API)

1. **تشغيل قاعدة البيانات PostGIS عبر Docker:**
   ```bash
   cd docker
   docker-compose up -d
   ```

2. **تشغيل الخادم (NestJS):**
   ```bash
   cd apps/backend
   npm install
   npm run build
   npm run start:dev
   ```
   - الـ API سيعمل على: `http://localhost:4000/api/v1`
   - توثيق Swagger التفاعلي متاح على: `http://localhost:4000/docs`

---

## 📱 تشغيل تطبيق الموبايل (Flutter App)

1. **تجهيز الاعتماديات وتشغيل التطبيق:**
   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```

---

## 🛡️ الأمان والخصوصية (Privacy & Safety)
- **Zero Exact Location Leaks:** لا يتم أبداً بث الموقع الدقيق لأي سائق للآخرين، ويتم استخدام معرفات مجهولة (Anonymous Handles) ونطاقات مكانية تقريبية.
- **Driver-Safe UI:** عناصر تفاعلية ضخمة لا تتطلب الكتابة أثناء القيادة، مع دعم كامل للوضع الليلي عالي التباين والتوجيهات الصوتية.
