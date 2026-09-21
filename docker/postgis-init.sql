-- DARB (دَرْب) - Iraqi Driver Intelligence & Navigation
-- PostgreSQL + PostGIS Schema & Spatial Indexes

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. Enum Types
DO $$ BEGIN
    CREATE TYPE user_trust_level AS ENUM ('BEGINNER', 'EXPLORER', 'ROAD_EXPERT', 'CITY_EYE', 'ROAD_LEGEND');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE report_type AS ENUM (
        'ACCIDENT', 'HEAVY_TRAFFIC', 'CLOSURE', 'DETOUR', 
        'CHECKPOINT', 'POTHOLE', 'HAZARD', 'WATER_ACCUMULATION', 
        'BROKEN_CAR', 'ROAD_WORK', 'OTHER'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE report_status AS ENUM ('ACTIVE', 'CONFIRMED', 'EXPIRED', 'RESOLVED', 'DISPUTED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE confirmation_vote AS ENUM ('CONFIRM', 'NOT_THERE_ANYMORE', 'NOT_SURE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE nidaa_question_type AS ENUM (
        'TRAFFIC', 'ROAD_CONDITION', 'ACCIDENT', 'CLOSURE', 
        'CHECKPOINT', 'FUEL_AVAILABILITY', 'WATER_FLOOD', 'GENERAL'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    username VARCHAR(50) NOT NULL,
    display_avatar VARCHAR(255),
    trust_level user_trust_level DEFAULT 'BEGINNER',
    reputation_score INT DEFAULT 0,
    helpful_answers_count INT DEFAULT 0,
    verified_reports_count INT DEFAULT 0,
    false_reports_count INT DEFAULT 0,
    fcm_token TEXT,
    preferred_language VARCHAR(5) DEFAULT 'ar',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Vehicles Table
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    fuel_type VARCHAR(20) DEFAULT 'PETROL',
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Road Reports Table
CREATE TABLE IF NOT EXISTS road_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type report_type NOT NULL,
    title VARCHAR(100),
    description TEXT,
    location GEOMETRY(Point, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    road_name VARCHAR(150),
    road_segment_id VARCHAR(100),
    bearing INT,
    confidence DOUBLE PRECISION DEFAULT 0.5,
    confirmations_count INT DEFAULT 0,
    rejections_count INT DEFAULT 0,
    ttl_seconds INT NOT NULL DEFAULT 1800,
    status report_status DEFAULT 'ACTIVE',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_road_reports_location ON road_reports USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_road_reports_status_expires ON road_reports(status, expires_at);

-- 5. Report Confirmations Table
CREATE TABLE IF NOT EXISTS report_confirmations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES road_reports(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    vote confirmation_vote NOT NULL,
    user_location GEOMETRY(Point, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Road Questions (نداء الطريق) Table
CREATE TABLE IF NOT EXISTS road_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    question_type nidaa_question_type NOT NULL,
    custom_text VARCHAR(200),
    location GEOMETRY(Point, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    bearing INT,
    target_radius_meters INT DEFAULT 15000,
    road_name VARCHAR(150),
    answers_yes INT DEFAULT 0,
    answers_no INT DEFAULT 0,
    answers_not_sure INT DEFAULT 0,
    total_answers INT DEFAULT 0,
    is_aggregated BOOLEAN DEFAULT FALSE,
    aggregated_report_id UUID REFERENCES road_reports(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_road_questions_location ON road_questions USING GIST(location);

CREATE TABLE IF NOT EXISTS road_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID REFERENCES road_questions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    answer VARCHAR(50) NOT NULL,
    responder_location GEOMETRY(Point, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Fuel Stations Table
CREATE TABLE IF NOT EXISTS fuel_stations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ar VARCHAR(150) NOT NULL,
    name_en VARCHAR(150),
    name_ku VARCHAR(150),
    location GEOMETRY(Point, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    city VARCHAR(50),
    address TEXT,
    phone VARCHAR(30),
    petrol_price INT DEFAULT 850,
    premium_price INT DEFAULT 1150,
    diesel_price INT DEFAULT 750,
    is_petrol_available BOOLEAN DEFAULT TRUE,
    crowd_level VARCHAR(20) DEFAULT 'LOW',
    rating DOUBLE PRECISION DEFAULT 4.5,
    is_verified BOOLEAN DEFAULT FALSE,
    price_updated_at TIMESTAMPTZ DEFAULT NOW(),
    price_source VARCHAR(50) DEFAULT 'COMMUNITY',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fuel_stations_location ON fuel_stations USING GIST(location);

CREATE TABLE IF NOT EXISTS fuel_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    station_id UUID REFERENCES fuel_stations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    report_type VARCHAR(30) NOT NULL,
    petrol_price INT,
    premium_price INT,
    diesel_price INT,
    crowd_level VARCHAR(20),
    is_available BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Place Categories & Places
CREATE TABLE IF NOT EXISTS place_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(50) UNIQUE NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_ku VARCHAR(100),
    icon VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES place_categories(id) ON DELETE RESTRICT,
    name_ar VARCHAR(150) NOT NULL,
    name_en VARCHAR(150),
    name_ku VARCHAR(150),
    location GEOMETRY(Point, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    phone VARCHAR(30),
    opening_hours VARCHAR(100),
    photos TEXT[],
    rating DOUBLE PRECISION DEFAULT 4.5,
    reviews_count INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_places_location ON places USING GIST(location);

-- 9. Trips Table
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    start_latitude DOUBLE PRECISION NOT NULL,
    start_longitude DOUBLE PRECISION NOT NULL,
    start_name VARCHAR(150),
    end_latitude DOUBLE PRECISION NOT NULL,
    end_longitude DOUBLE PRECISION NOT NULL,
    end_name VARCHAR(150),
    distance_km DOUBLE PRECISION NOT NULL,
    duration_seconds INT NOT NULL,
    avg_speed_kmh DOUBLE PRECISION NOT NULL,
    trusted_max_speed_kmh DOUBLE PRECISION NOT NULL,
    stops_count INT DEFAULT 0,
    traffic_delay_seconds INT DEFAULT 0,
    route_polyline TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Badges & User Badges
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(50) UNIQUE NOT NULL,
    title_ar VARCHAR(100) NOT NULL,
    title_en VARCHAR(100) NOT NULL,
    description_ar TEXT,
    icon VARCHAR(100) NOT NULL,
    required_points INT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- 11. Initial Iraqi Seed Data
INSERT INTO place_categories (key, name_ar, name_en, name_ku, icon) VALUES
('fuel', 'محطات وقود', 'Fuel Stations', 'وێستگەی سووتەمەنی', 'local_gas_station'),
('mechanic', 'ورش وميكانيك', 'Mechanics', 'وەستای میکانیک', 'build'),
('tire_repair', 'بنجرجية', 'Tire Repair', 'پەنجەرچی', 'tire_repair'),
('towing', 'سطحة وإنقاذ', 'Towing Services', 'فریادکەوتنی ئۆتۆمبێل', 'car_crash'),
('car_wash', 'غسيل سيارات', 'Car Wash', 'شوشتنی ئۆتۆمبێل', 'local_car_wash'),
('restaurant', 'مطاعم واستراحات', 'Restaurants', 'چێشتخانەکان', 'restaurant'),
('cafe', 'كافيهات', 'Cafes', 'کافتریا', 'local_cafe'),
('pharmacy', 'صيدليات', 'Pharmacies', 'دەرمانخانە', 'local_pharmacy'),
('hospital', 'مستشفيات', 'Hospitals', 'نەخۆشخانە', 'local_hospital')
ON CONFLICT (key) DO NOTHING;

-- Initial Badges
INSERT INTO badges (slug, title_ar, title_en, description_ar, icon, required_points) VALUES
('eye_of_erbil', 'عين أربيل', 'Eye of Erbil', 'أكثر من 20 بلاغ دقيق ومؤكد في أربيل وضواحيها', 'visibility', 50),
('road_expert', 'خبير الطرق', 'Road Expert', 'المساهمة في تأكيد 50 بلاغاً والإجابة على نداء الطريق', 'verified', 150),
('travel_king', 'ملك السفر', 'Travel King', 'قطع أكثر من 1,000 كم على الطرق السريعة بين المدن', 'navigation', 300),
('iraq_explorer', 'مستكشف العراق', 'Iraq Explorer', 'القيادة في أكثر من 4 محافظات عراقية مختلفة', 'public', 600)
ON CONFLICT (slug) DO NOTHING;
