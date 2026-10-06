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
      id: 'erbil-station-0',
      nameAr: 'محطة كاڤين كروب - 100 متري',
      nameEn: 'Kavin Group Station - 100M',
      nameKu: 'Kavin Group Station - 100M', 
      latitude: 36.195,
      longitude: 44.01,
      city: 'Erbil',
      address: '100m Road, Erbil',
      phone: '+9647501000000',
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
      id: 'erbil-station-1',
      nameAr: 'محطة فلورا',
      nameEn: 'Flora Petrol Station',
      nameKu: 'Flora Petrol Station', 
      latitude: 36.2105,
      longitude: 43.998,
      city: 'Erbil',
      address: '60m Road, Erbil',
      phone: '+9647501000001',
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
      id: 'erbil-station-2',
      nameAr: 'محطة زاگروس',
      nameEn: 'Zagros Fuel Station',
      nameKu: 'Zagros Fuel Station', 
      latitude: 36.175,
      longitude: 44.025,
      city: 'Erbil',
      address: 'Kirkuk Road, Erbil',
      phone: '+9647501000002',
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
      id: 'erbil-station-3',
      nameAr: 'محطة ستير',
      nameEn: 'Ster Petrol',
      nameKu: 'Ster Petrol', 
      latitude: 36.1855,
      longitude: 43.9855,
      city: 'Erbil',
      address: 'Mosul Road, Erbil',
      phone: '+9647501000003',
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
      id: 'erbil-station-4',
      nameAr: 'محطة كوردنەوت - فاملي مول',
      nameEn: 'KurdNeft - Family Mall',
      nameKu: 'KurdNeft - Family Mall', 
      latitude: 36.189,
      longitude: 43.982,
      city: 'Erbil',
      address: 'Peshawa Qazi St, Erbil',
      phone: '+9647501000004',
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
      id: 'erbil-station-5',
      nameAr: 'محطة كوردنەوت - 120 متري',
      nameEn: 'KurdNeft - 120M Road',
      nameKu: 'KurdNeft - 120M Road', 
      latitude: 36.219,
      longitude: 43.992,
      city: 'Erbil',
      address: '120m Road, Erbil',
      phone: '+9647501000005',
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
      id: 'erbil-station-6',
      nameAr: 'محطة كورد بترول - شارع بارزاني',
      nameEn: 'Kurd Petrol - Barzani St',
      nameKu: 'Kurd Petrol - Barzani St', 
      latitude: 36.193,
      longitude: 44.004,
      city: 'Erbil',
      address: 'Barzani Namir St, Erbil',
      phone: '+9647501000006',
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
      id: 'erbil-station-7',
      nameAr: 'محطة شير',
      nameEn: 'Sher Fuel Station',
      nameKu: 'Sher Fuel Station', 
      latitude: 36.165,
      longitude: 44.01,
      city: 'Erbil',
      address: 'Erbil South, Erbil',
      phone: '+9647501000007',
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
      id: 'erbil-station-8',
      nameAr: 'محطة طريق اربيل',
      nameEn: 'Tareeq Erbil Station',
      nameKu: 'Tareeq Erbil Station', 
      latitude: 36.2,
      longitude: 44.03,
      city: 'Erbil',
      address: 'Koya Road, Erbil',
      phone: '+9647501000008',
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
      id: 'erbil-station-9',
      nameAr: 'محطة عينكاوا',
      nameEn: 'Ankawa Petrol Station',
      nameKu: 'Ankawa Petrol Station', 
      latitude: 36.225,
      longitude: 43.99,
      city: 'Erbil',
      address: 'Ankawa, Erbil',
      phone: '+9647501000009',
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
      id: 'erbil-station-10',
      nameAr: 'محطة شقلاوة',
      nameEn: 'Shaqlawa Road Station',
      nameKu: 'Shaqlawa Road Station', 
      latitude: 36.23,
      longitude: 44.05,
      city: 'Erbil',
      address: 'Shaqlawa Road, Erbil',
      phone: '+9647501000010',
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
      id: 'erbil-station-11',
      nameAr: 'محطة مخمور',
      nameEn: 'Makhmour Road Station',
      nameKu: 'Makhmour Road Station', 
      latitude: 36.15,
      longitude: 43.98,
      city: 'Erbil',
      address: 'Makhmour Road, Erbil',
      phone: '+9647501000011',
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
      id: 'erbil-station-12',
      nameAr: 'محطة كوردستان',
      nameEn: 'Kurdistan Fuel',
      nameKu: 'Kurdistan Fuel', 
      latitude: 36.18,
      longitude: 43.99,
      city: 'Erbil',
      address: '40m Road, Erbil',
      phone: '+9647501000012',
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
      id: 'erbil-station-13',
      nameAr: 'محطة هولير',
      nameEn: 'Hawler Station',
      nameKu: 'Hawler Station', 
      latitude: 36.19,
      longitude: 44.0,
      city: 'Erbil',
      address: '60m Road, Erbil',
      phone: '+9647501000013',
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
      id: 'erbil-station-14',
      nameAr: 'محطة نور',
      nameEn: 'Noor Petrol',
      nameKu: 'Noor Petrol', 
      latitude: 36.17,
      longitude: 43.97,
      city: 'Erbil',
      address: 'Mosul Road, Erbil',
      phone: '+9647501000014',
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
      id: 'erbil-station-15',
      nameAr: 'محطة جيهان',
      nameEn: 'Cihan Fuel Station',
      nameKu: 'Cihan Fuel Station', 
      latitude: 36.185,
      longitude: 43.96,
      city: 'Erbil',
      address: 'Gulan Street, Erbil',
      phone: '+9647501000015',
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
      id: 'erbil-station-16',
      nameAr: 'محطة امباير',
      nameEn: 'Empire Fuel',
      nameKu: 'Empire Fuel', 
      latitude: 36.175,
      longitude: 43.98,
      city: 'Erbil',
      address: 'Empire World, Erbil',
      phone: '+9647501000016',
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
      id: 'erbil-station-17',
      nameAr: 'محطة بختياري',
      nameEn: 'Bakhtiari Station',
      nameKu: 'Bakhtiari Station', 
      latitude: 36.195,
      longitude: 43.995,
      city: 'Erbil',
      address: 'Bakhtiari, Erbil',
      phone: '+9647501000017',
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
      id: 'erbil-station-18',
      nameAr: 'محطة وزيران',
      nameEn: 'Waziran Fuel',
      nameKu: 'Waziran Fuel', 
      latitude: 36.185,
      longitude: 44.015,
      city: 'Erbil',
      address: 'Waziran, Erbil',
      phone: '+9647501000018',
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
      id: 'erbil-station-19',
      nameAr: 'محطة روناكي',
      nameEn: 'Ronaki Petrol',
      nameKu: 'Ronaki Petrol', 
      latitude: 36.205,
      longitude: 44.005,
      city: 'Erbil',
      address: 'Ronaki, Erbil',
      phone: '+9647501000019',
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
      id: 'erbil-station-20',
      nameAr: 'محطة زيلان',
      nameEn: 'Zilan Station',
      nameKu: 'Zilan Station', 
      latitude: 36.215,
      longitude: 44.025,
      city: 'Erbil',
      address: 'Zilan, Erbil',
      phone: '+9647501000020',
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
      id: 'erbil-station-21',
      nameAr: 'محطة فرمانبران',
      nameEn: 'Farmanbaran Fuel',
      nameKu: 'Farmanbaran Fuel', 
      latitude: 36.16,
      longitude: 44.03,
      city: 'Erbil',
      address: 'Farmanbaran, Erbil',
      phone: '+9647501000021',
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
      id: 'erbil-station-22',
      nameAr: 'محطة هافالان',
      nameEn: 'Havalan Station',
      nameKu: 'Havalan Station', 
      latitude: 36.155,
      longitude: 44.02,
      city: 'Erbil',
      address: 'Havalan, Erbil',
      phone: '+9647501000022',
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
      id: 'erbil-station-23',
      nameAr: 'محطة شورش',
      nameEn: 'Shorish Petrol',
      nameKu: 'Shorish Petrol', 
      latitude: 36.205,
      longitude: 44.035,
      city: 'Erbil',
      address: 'Shorish, Erbil',
      phone: '+9647501000023',
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
      id: 'erbil-station-24',
      nameAr: 'محطة برايتي',
      nameEn: 'Brayati Fuel',
      nameKu: 'Brayati Fuel', 
      latitude: 36.21,
      longitude: 44.01,
      city: 'Erbil',
      address: 'Brayati, Erbil',
      phone: '+9647501000024',
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
