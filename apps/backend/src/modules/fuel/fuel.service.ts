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
      id: 'erbil-kavin-1',
      nameAr: 'محطة كاڤين كروب - 100 متري',
      nameEn: 'Kavin Group Station - 100M',
      nameKu: 'وێستگەی کاڤین گروپ - 100 مەتری',
      latitude: 36.1950,
      longitude: 44.0100,
      city: 'Erbil',
      address: '100m Road, Erbil',
      phone: '+9647501111111',
      petrolPrice: null,
      premiumPrice: null,
      dieselPrice: null,
      isPetrolAvailable: true,
      crowdLevel: 'UNKNOWN',
      rating: 0,
      isVerified: true,
      priceUpdatedAt: new Date(),
      priceSource: 'COMMUNITY',
    },
    {
      id: 'erbil-flora',
      nameAr: 'محطة فلورا',
      nameEn: 'Flora Petrol Station',
      nameKu: 'وێستگەی فلۆرا',
      latitude: 36.2105,
      longitude: 43.9980,
      city: 'Erbil',
      address: '60m Road, Erbil',
      phone: '+9647502222222',
      petrolPrice: null,
      premiumPrice: null,
      dieselPrice: null,
      isPetrolAvailable: true,
      crowdLevel: 'UNKNOWN',
      rating: 0,
      isVerified: true,
      priceUpdatedAt: new Date(),
      priceSource: 'COMMUNITY',
    },
    {
      id: 'erbil-zagros',
      nameAr: 'محطة زاگروس',
      nameEn: 'Zagros Fuel Station',
      nameKu: 'وێستگەی زاگرۆس',
      latitude: 36.1750,
      longitude: 44.0250,
      city: 'Erbil',
      address: 'Kirkuk Road, Erbil',
      phone: '+9647503333333',
      petrolPrice: null,
      premiumPrice: null,
      dieselPrice: null,
      isPetrolAvailable: true,
      crowdLevel: 'UNKNOWN',
      rating: 0,
      isVerified: true,
      priceUpdatedAt: new Date(),
      priceSource: 'COMMUNITY',
    },
    {
      id: 'erbil-ster',
      nameAr: 'محطة ستير',
      nameEn: 'Ster Petrol',
      nameKu: 'وێستگەی ستێر',
      latitude: 36.1855,
      longitude: 43.9855,
      city: 'Erbil',
      address: 'Mosul Road, Erbil',
      phone: '+9647504444444',
      petrolPrice: null,
      premiumPrice: null,
      dieselPrice: null,
      isPetrolAvailable: true,
      crowdLevel: 'UNKNOWN',
      rating: 0,
      isVerified: true,
      priceUpdatedAt: new Date(),
      priceSource: 'COMMUNITY',
    }
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
