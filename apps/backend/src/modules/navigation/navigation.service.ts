import { Injectable } from '@nestjs/common';
import { CalculateRouteDto } from './dto/navigation.dto';
import { ReportsService } from '../reports/reports.service';
import { RoutingService } from '../routing/routing.service';
import { GeoUtils } from '../../common/utils/geo.utils';

@Injectable()
export class NavigationService {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly routingService: RoutingService,
  ) {}

  async calculateRoutes(dto: CalculateRouteDto) {
    let routingData;
    try {
      routingData = await this.routingService.calculateRoute(
        dto.originLat,
        dto.originLng,
        dto.destLat,
        dto.destLng,
      );
    } catch (e) {
      throw new Error('فشل في جلب المسار من مزود الخرائط');
    }

    const midpointLat = (dto.originLat + dto.destLat) / 2;
    const midpointLng = (dto.originLng + dto.destLng) / 2;
    const totalDistanceMeters = GeoUtils.haversineDistance(
        dto.originLat,
        dto.originLng,
        dto.destLat,
        dto.destLng,
    );

    const reportsAlongRoute = await this.reportsService.getNearbyReports(
      midpointLat,
      midpointLng,
      totalDistanceMeters * 0.7,
    );

    const routes = routingData.routes.map((route: any, idx: number) => {
      const distanceKm = Math.round((route.distanceMeters / 1000) * 10) / 10;
      const durationSeconds = parseInt(route.duration.replace('s', ''));
      const durationMins = Math.round(durationSeconds / 60);

      return {
        id: route.id,
        name: idx === 0 ? 'المسار الأسرع' : 'مسار بديل ' + idx,
        distanceKm,
        durationMins,
        durationSeconds,
        trafficDelayMins: 0,
        reportsCount: reportsAlongRoute.length,
        isRecommended: idx === 0,
        tags: idx === 0 ? ['أسرع', 'ينصح به'] : ['بديل'],
        geometry: route.polyline,
        legs: route.legs,
      };
    });

    return {
      origin: dto.originName || 'موقعي',
      destination: dto.destName || 'الوجهة',
      routes,
      incidentsOnRoutes: reportsAlongRoute,
    };
  }
}
