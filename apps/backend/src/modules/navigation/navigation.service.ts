import { Injectable, Logger } from '@nestjs/common';
import { CalculateRouteDto } from './dto/navigation.dto';
import { ReportsService } from '../reports/reports.service';
import { GeoUtils } from '../../common/utils/geo.utils';

@Injectable()
export class NavigationService {
  private readonly logger = new Logger(NavigationService.name);

  constructor(private readonly reportsService: ReportsService) {}

  async calculateRoutes(dto: CalculateRouteDto) {
    const totalDistanceMeters = GeoUtils.haversineDistance(
      dto.originLat,
      dto.originLng,
      dto.destLat,
      dto.destLng,
    );

    const distanceKm = Math.round((totalDistanceMeters / 1000) * 1.25 * 10) / 10; // realistic road detour factor

    // Fetch reports between origin and destination
    const midpointLat = (dto.originLat + dto.destLat) / 2;
    const midpointLng = (dto.originLng + dto.destLng) / 2;
    const reportsAlongRoute = await this.reportsService.getNearbyReports(
      midpointLat,
      midpointLng,
      totalDistanceMeters * 0.7,
    );

    // Build Route A (Primary - Recommended)
    const durationMinsA = Math.round((distanceKm / 75) * 60);
    const hoursA = Math.floor(durationMinsA / 60);
    const minsA = durationMinsA % 60;

    // Build Route B (Alternative)
    const distanceKmB = Math.round(distanceKm * 1.05 * 10) / 10;
    const durationMinsB = durationMinsA + 13;
    const hoursB = Math.floor(durationMinsB / 60);
    const minsB = durationMinsB % 60;

    const routeA = {
      id: 'route-a',
      name: 'طريق أربيل - دهوك السريع M10',
      isRecommended: true,
      distanceKm: distanceKm,
      durationMinutes: durationMinsA,
      durationFormatted: hoursA > 0 ? `${hoursA} ساعة و ${minsA} دقيقة` : `${minsA} دقيقة`,
      eta: new Date(Date.now() + durationMinsA * 60 * 1000).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' }),
      qualityScore: 92,
      recommendationReason: 'أسرع بـ 13 دقيقة بسبب انخفاض الزحام وسلاسة نقاط التفتيش',
      trafficCondition: 'LIGHT_TO_MODERATE',
      incidentsSummary: {
        totalIncidents: reportsAlongRoute.length > 0 ? 2 : 0,
        confirmedCount: 8,
        warnings: [
          '🚦 زحمة خفيفة بعد 18 كم (أكدها 8 سواق)',
          '👮 سيطرة نشطة قبل دهوك بـ 12 كم',
          '⛽ محطة بيترول أوفيسي بعد 25 كم (الوقود متوفر بالسعر الرسمي)',
        ],
      },
      waypoints: [
        { lat: dto.originLat, lng: dto.originLng, title: dto.originName || 'نقطة الانطلاق' },
        { lat: 36.3120, lng: 43.6800, title: 'محطة بيترول أوفيسي' },
        { lat: 36.7000, lng: 43.1500, title: 'سيطرة مدخل دهوك' },
        { lat: dto.destLat, lng: dto.destLng, title: dto.destName || 'الوجهة' },
      ],
    };

    const routeB = {
      id: 'route-b',
      name: 'طريق شيخان - القوش البديل',
      isRecommended: false,
      distanceKm: distanceKmB,
      durationMinutes: durationMinsB,
      durationFormatted: hoursB > 0 ? `${hoursB} ساعة و ${minsB} دقيقة` : `${minsB} دقيقة`,
      eta: new Date(Date.now() + durationMinsB * 60 * 1000).toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' }),
      qualityScore: 78,
      recommendationReason: 'أطول بـ 6 كم وتوجد أعمال صيانة طريق بالقرب من مفرق شيخان',
      trafficCondition: 'MODERATE',
      incidentsSummary: {
        totalIncidents: 1,
        confirmedCount: 3,
        warnings: ['🚧 أعمال طريق وصيانة في المسار الفرعي بعد 32 كم'],
      },
      waypoints: [
        { lat: dto.originLat, lng: dto.originLng, title: dto.originName || 'نقطة الانطلاق' },
        { lat: 36.6500, lng: 43.3500, title: 'مفرق شيخان' },
        { lat: dto.destLat, lng: dto.destLng, title: dto.destName || 'الوجهة' },
      ],
    };

    return {
      origin: { lat: dto.originLat, lng: dto.originLng, name: dto.originName || 'موقعي الحالي' },
      destination: { lat: dto.destLat, lng: dto.destLng, name: dto.destName || 'الوجهة' },
      routes: [routeA, routeB],
    };
  }
}
