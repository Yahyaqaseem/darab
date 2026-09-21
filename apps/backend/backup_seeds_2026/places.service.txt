import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { GeoUtils } from '../../common/utils/geo.utils';

@Injectable()
export class PlacesService {
  private readonly logger = new Logger(PlacesService.name);
  private memoryPlaces: any[] = [];
  private memoryCategories: any[] = [];

  constructor(private readonly db: DatabaseService) {
    this.seedPlacesAndCategories();
  }

  private seedPlacesAndCategories() {
    this.memoryCategories = [
      { id: 'cat-fuel', key: 'fuel', nameAr: 'محطات وقود', nameEn: 'Fuel Stations', icon: 'local_gas_station' },
      { id: 'cat-mechanic', key: 'mechanic', nameAr: 'ورش وميكانيك', nameEn: 'Mechanics', icon: 'build' },
      { id: 'cat-tire', key: 'tire_repair', nameAr: 'بنجرجية', nameEn: 'Tire Repair', icon: 'tire_repair' },
      { id: 'cat-towing', key: 'towing', nameAr: 'سطحة وإنقاذ', nameEn: 'Towing Services', icon: 'car_crash' },
      { id: 'cat-wash', key: 'car_wash', nameAr: 'غسيل سيارات', nameEn: 'Car Wash', icon: 'local_car_wash' },
      { id: 'cat-restaurant', key: 'restaurant', nameAr: 'مطاعم واستراحات', nameEn: 'Restaurants', icon: 'restaurant' },
      { id: 'cat-cafe', key: 'cafe', nameAr: 'كافيهات', nameEn: 'Cafes', icon: 'local_cafe' },
      { id: 'cat-pharmacy', key: 'pharmacy', nameAr: 'صيدليات', nameEn: 'Pharmacies', icon: 'local_pharmacy' },
    ];

    this.memoryPlaces = [
      {
        id: 'place-1',
        categoryKey: 'tire_repair',
        nameAr: 'بنجرجي وتصليح إطارات السريع',
        nameEn: 'Express Tire Repair',
        nameKu: 'پەنجەرچی خێرا',
        latitude: 36.1980,
        longitude: 44.0120,
        address: 'أربيل - شارع 60 متري قرب تقاطع الشورجة',
        phone: '+9647509871122',
        openingHours: 'مفتوح 24 ساعة',
        rating: 4.8,
        reviewsCount: 34,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=600'],
      },
      {
        id: 'place-2',
        categoryKey: 'towing',
        nameAr: 'سطحة كوردستان للإنقاذ السريع',
        nameEn: 'Kurdistan Fast Towing',
        nameKu: 'فریادکەوتنی ئۆتۆمبێل',
        latitude: 36.2100,
        longitude: 44.0200,
        address: 'تغطية كاملة لطرق أربيل - دهوك - السليمانية',
        phone: '+9647501112233',
        openingHours: 'طوارئ 24/7',
        rating: 4.9,
        reviewsCount: 68,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600'],
      },
      {
        id: 'place-3',
        categoryKey: 'mechanic',
        nameAr: 'المركز الألماني لصيانة السيارات',
        nameEn: 'German Auto Care Center',
        nameKu: 'سەنتەری ئەڵمانی بۆ چاککردنی ئۆتۆمبێل',
        latitude: 36.1850,
        longitude: 44.0300,
        address: 'أربيل - المنطقة الصناعية الجنوبية',
        phone: '+9647505557788',
        openingHours: '08:00 ص - 08:00 م',
        rating: 4.7,
        reviewsCount: 52,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=600'],
      },
      {
        id: 'place-4',
        categoryKey: 'restaurant',
        nameAr: 'مطعم واستراحة طريق دهوك',
        nameEn: 'Duhok Road Rest & Grill',
        nameKu: 'چێشتخانەی ڕێگای دهۆک',
        latitude: 36.4200,
        longitude: 43.5500,
        address: 'طريق أربيل - دهوك قرب بحيرة سيميل',
        phone: '+9647503332211',
        openingHours: '07:00 ص - 12:00 منتصف الليل',
        rating: 4.6,
        reviewsCount: 89,
        isVerified: true,
        photos: ['https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600'],
      },
    ];
  }

  private placeReviews = new Map<string, any[]>([
    ['place-1', [
      { id: 'rev-1', userId: 'user-a', rating: 5, comment: 'شغل نظيف وسريع في تبديل الإطار', createdAt: new Date(Date.now() - 3600000).toISOString() },
      { id: 'rev-2', userId: 'user-b', rating: 4.5, comment: 'متواجدين في وقت متأخر من الليل، بارك الله بكم', createdAt: new Date(Date.now() - 86400000).toISOString() },
    ]],
    ['place-2', [
      { id: 'rev-3', userId: 'user-c', rating: 5, comment: 'وصلوا خلال 15 دقيقة لطريق دهوك، قمة في الأخلاق', createdAt: new Date(Date.now() - 7200000).toISOString() },
    ]],
  ]);

  async getCategories() {
    return this.memoryCategories;
  }

  async getNearbyPlaces(lat: number, lng: number, categoryKey?: string, radiusMeters: number = 30000) {
    const results = this.memoryPlaces
      .filter((p) => !categoryKey || p.categoryKey === categoryKey)
      .map((p) => {
        const dist = GeoUtils.haversineDistance(lat, lng, p.latitude, p.longitude);
        return {
          ...p,
          distanceMeters: Math.round(dist),
          distanceKm: Math.round((dist / 1000) * 10) / 10,
        };
      })
      .filter((p) => p.distanceMeters <= radiusMeters)
      .sort((a, b) => a.distanceMeters - b.distanceMeters);

    return results;
  }

  async searchPlaces(query: string, lat?: number, lng?: number) {
    const q = query.trim().toLowerCase();
    const matches = this.memoryPlaces.filter((p) => {
      const matchAr = p.nameAr?.toLowerCase().includes(q);
      const matchEn = p.nameEn?.toLowerCase().includes(q);
      const matchKu = p.nameKu?.toLowerCase().includes(q);
      const matchAddress = p.address?.toLowerCase().includes(q);
      const matchCategory = p.categoryKey?.toLowerCase().includes(q);
      return matchAr || matchEn || matchKu || matchAddress || matchCategory;
    });

    if (lat !== undefined && lng !== undefined) {
      return matches.map((p) => {
        const dist = GeoUtils.haversineDistance(lat, lng, p.latitude, p.longitude);
        return {
          ...p,
          distanceMeters: Math.round(dist),
          distanceKm: Math.round((dist / 1000) * 10) / 10,
        };
      }).sort((a, b) => a.distanceMeters - b.distanceMeters);
    }

    return matches;
  }

  async getPlaceById(id: string) {
    const place = this.memoryPlaces.find((p) => p.id === id);
    if (!place) throw new NotFoundException('المكان غير موجود');
    const reviews = this.placeReviews.get(id) || [];
    return {
      ...place,
      reviews,
    };
  }

  async addReview(placeId: string, userId: string, dto: { rating: number; comment?: string }) {
    const place = this.memoryPlaces.find((p) => p.id === placeId);
    if (!place) throw new NotFoundException('المكان غير موجود');

    const reviews = this.placeReviews.get(placeId) || [];
    
    // Check if user already reviewed
    const existingIndex = reviews.findIndex((r) => r.userId === userId);
    const newReview = {
      id: `rev-${Date.now()}`,
      userId,
      rating: Math.max(1, Math.min(5, dto.rating)),
      comment: dto.comment?.trim() || '',
      createdAt: new Date().toISOString(),
    };

    if (existingIndex !== -1) {
      reviews[existingIndex] = newReview;
    } else {
      reviews.unshift(newReview);
    }

    this.placeReviews.set(placeId, reviews);

    // Recalculate average rating
    const sum = reviews.reduce((acc, r) => acc + r.rating, 0);
    place.rating = Math.round((sum / reviews.length) * 10) / 10;
    place.reviewsCount = reviews.length;

    return {
      success: true,
      message: 'شكراً لتقييمك ومساعدتك لإخوانك السائقين',
      review: newReview,
      updatedRating: place.rating,
      reviewsCount: place.reviewsCount,
    };
  }

  async createPlace(dto: any) {
    // Duplicate Detection: check distance < 120m or exact phone match
    for (const p of this.memoryPlaces) {
      if (dto.phone && p.phone === dto.phone) {
        return {
          success: false,
          isDuplicate: true,
          message: 'هذا المكان مسجل مسبقاً بنفس رقم الهاتف',
          existingPlace: p,
        };
      }

      const dist = GeoUtils.haversineDistance(dto.latitude, dto.longitude, p.latitude, p.longitude);
      if (dist < 120 && p.categoryKey === dto.categoryKey) {
        return {
          success: false,
          isDuplicate: true,
          message: 'يوجد مكان مسجل بنفس التصنيف والموقع الجغرافي',
          existingPlace: p,
        };
      }
    }

    const newPlace = {
      id: `place-${Date.now()}`,
      categoryKey: dto.categoryKey,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn || dto.nameAr,
      nameKu: dto.nameKu || dto.nameAr,
      latitude: dto.latitude,
      longitude: dto.longitude,
      address: dto.address || 'العراق',
      phone: dto.phone || null,
      openingHours: dto.openingHours || 'يومياً',
      rating: 5.0,
      reviewsCount: 1,
      isVerified: false,
      photos: [],
      createdAt: new Date().toISOString(),
    };

    this.memoryPlaces.push(newPlace);

    return {
      success: true,
      message: 'تمت إضافة المكان بنجاح وسيتم تدقيقه وتثبيته على خريطة درب',
      place: newPlace,
    };
  }
}
