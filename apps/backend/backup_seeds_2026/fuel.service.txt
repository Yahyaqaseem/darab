import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { UpdateFuelReportDto } from './dto/fuel.dto';
import { GeoUtils } from '../../common/utils/geo.utils';

@Injectable()
export class FuelService {
  private readonly logger = new Logger(FuelService.name);
  private memoryStations = new Map<string, any>();

  constructor(private readonly db: DatabaseService) {
    this.seedIraqiFuelStations();
  }

  private seedIraqiFuelStations() {
    const stations = [
      {
        id: 'fuel-1',
        nameAr: 'محطة وقود كوردستان 100 متري',
        nameEn: 'Kurdistan 100m Fuel Station',
        nameKu: 'وێستگەی سووتەمەنی کوردستان',
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
        priceUpdatedAt: new Date(Date.now() - 35 * 60 * 1000), // 35 mins ago
        priceSource: 'COMMUNITY',
      },
      {
        id: 'fuel-2',
        nameAr: 'محطة وقود بيترول أوفيسي (طريق دهوك)',
        nameEn: 'Petrol Ofisi - Duhok Road',
        nameKu: 'وێستگەی پترۆل ئۆفیسی',
        latitude: 36.3120,
        longitude: 43.6800,
        city: 'أربيل - دهوك',
        address: 'طريق أربيل - دهوك السريع M10',
        phone: '+9647504443322',
        petrolPrice: 950,
        premiumPrice: 1250,
        dieselPrice: 800,
        isPetrolAvailable: true,
        crowdLevel: 'MEDIUM',
        rating: 4.8,
        isVerified: true,
        priceUpdatedAt: new Date(Date.now() - 15 * 60 * 1000),
        priceSource: 'OFFICIAL_OWNER',
      },
      {
        id: 'fuel-3',
        nameAr: 'محطة وقود اليرموك الحكومية',
        nameEn: 'Al-Yarmouk Governmental Fuel Station',
        nameKu: 'وێستگەی یەرموک',
        latitude: 33.3050,
        longitude: 44.3520,
        city: 'بغداد',
        address: 'جانب الكرخ - ساحة اليرموك',
        phone: '+9647801122334',
        petrolPrice: 450, // المدعوم الحكومي
        premiumPrice: 850,
        dieselPrice: 400,
        isPetrolAvailable: true,
        crowdLevel: 'HIGH',
        rating: 4.2,
        isVerified: true,
        priceUpdatedAt: new Date(Date.now() - 50 * 60 * 1000),
        priceSource: 'USER_REPORT',
      },
      {
        id: 'fuel-4',
        nameAr: 'محطة استراحة طريق المرور السريع',
        nameEn: 'Highway 1 Rest & Fuel Station',
        nameKu: 'وێستگەی ڕێگای خێرا',
        latitude: 32.5500,
        longitude: 44.4200,
        city: 'بابل / طريق الجنوب',
        address: 'طريق المرور السريع رقم 1 - قرب الحلة',
        phone: '+9647709876543',
        petrolPrice: 850,
        premiumPrice: 1100,
        dieselPrice: 750,
        isPetrolAvailable: true,
        crowdLevel: 'LOW',
        rating: 4.5,
        isVerified: false,
        priceUpdatedAt: new Date(Date.now() - 120 * 60 * 1000),
        priceSource: 'COMMUNITY',
      },
    ];

    for (const s of stations) {
      this.memoryStations.set(s.id, s);
    }
  }

  private computeFreshness(priceUpdatedAt: Date | string): { category: 'FRESH' | 'RECENT' | 'OUTDATED'; label: string; confidence: number } {
    const updated = new Date(priceUpdatedAt).getTime();
    const diffMins = Math.round((Date.now() - updated) / (60 * 1000));

    if (diffMins < 60) {
      return {
        category: 'FRESH',
        label: diffMins <= 1 ? 'محدث للتو' : `محدث منذ ${diffMins} دقيقة`,
        confidence: 0.98,
      };
    } else if (diffMins < 360) {
      const hours = Math.floor(diffMins / 60);
      return {
        category: 'RECENT',
        label: `محدث منذ ${hours} ساعة`,
        confidence: 0.85,
      };
    } else if (diffMins < 1440) {
      const hours = Math.floor(diffMins / 60);
      return {
        category: 'RECENT',
        label: `محدث منذ ${hours} ساعة`,
        confidence: 0.65,
      };
    } else {
      const days = Math.floor(diffMins / 1440);
      return {
        category: 'OUTDATED',
        label: `محدث منذ ${days} يوم (بحاجة لتأكيد)`,
        confidence: 0.40,
      };
    }
  }

  async getNearbyFuelStations(lat: number, lng: number, radiusMeters: number = 25000) {
    if (this.db.isDbConnected) {
      try {
        const res = await this.db.query(
          `SELECT id, name_ar as "nameAr", name_en as "nameEn", name_ku as "nameKu",
                  latitude, longitude, city, address, phone, petrol_price as "petrolPrice",
                  premium_price as "premiumPrice", diesel_price as "dieselPrice",
                  is_petrol_available as "isPetrolAvailable", crowd_level as "crowdLevel",
                  rating, is_verified as "isVerified", price_updated_at as "priceUpdatedAt",
                  price_source as "priceSource",
                  ST_Distance(location::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) as "distanceMeters"
           FROM fuel_stations
           WHERE ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3)
           ORDER BY "distanceMeters" ASC`,
          [lng, lat, radiusMeters],
        );
        if (res.rows.length > 0) {
          return res.rows.map((station) => {
            const freshness = this.computeFreshness(station.priceUpdatedAt);
            return {
              ...station,
              distanceKm: Math.round((Number(station.distanceMeters) / 1000) * 10) / 10,
              freshnessCategory: freshness.category,
              freshnessLabel: freshness.label,
              freshnessConfidence: freshness.confidence,
            };
          });
        }
      } catch (err: any) {
        this.logger.warn(`PostGIS query failed in getNearbyFuelStations: ${err.message}`);
      }
    }

    const results: any[] = [];
    for (const s of this.memoryStations.values()) {
      const dist = GeoUtils.haversineDistance(lat, lng, s.latitude, s.longitude);
      if (dist <= radiusMeters) {
        const freshness = this.computeFreshness(s.priceUpdatedAt);
        results.push({
          ...s,
          distanceMeters: Math.round(dist),
          distanceKm: Math.round((dist / 1000) * 10) / 10,
          freshnessCategory: freshness.category,
          freshnessLabel: freshness.label,
          freshnessConfidence: freshness.confidence,
        });
      }
    }

    return results.sort((a, b) => a.distanceMeters - b.distanceMeters);
  }

  async updateFuelStation(stationId: string, userId: string, dto: UpdateFuelReportDto) {
    let station = this.memoryStations.get(stationId);

    if (!station) {
      throw new NotFoundException('محطة الوقود غير موجودة');
    }

    if (dto.petrolPrice !== undefined) station.petrolPrice = dto.petrolPrice;
    if (dto.premiumPrice !== undefined) station.premiumPrice = dto.premiumPrice;
    if (dto.dieselPrice !== undefined) station.dieselPrice = dto.dieselPrice;
    if (dto.isAvailable !== undefined) station.isPetrolAvailable = dto.isAvailable;
    if (dto.crowdLevel !== undefined) station.crowdLevel = dto.crowdLevel;

    station.priceUpdatedAt = new Date();
    station.priceSource = 'COMMUNITY';

    this.memoryStations.set(stationId, station);

    const freshness = this.computeFreshness(station.priceUpdatedAt);
    const enrichedStation = {
      ...station,
      freshnessCategory: freshness.category,
      freshnessLabel: freshness.label,
      freshnessConfidence: freshness.confidence,
    };

    return {
      success: true,
      message: 'تم تحديث بيانات المحطة والأسعار بنجاح! شكراً لمساهمتك مع إخوانك السائقين.',
      station: enrichedStation,
    };
  }
}
