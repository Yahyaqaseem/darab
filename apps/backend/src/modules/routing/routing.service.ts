import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';

@Injectable()
export class RoutingService {
  private readonly logger = new Logger(RoutingService.name);
  private readonly OSRM_API_URL = 'http://router.project-osrm.org/route/v1/driving';

  constructor(private readonly httpService: HttpService) {}

  async calculateRoute(originLat: number, originLng: number, destLat: number, destLng: number) {
    try {
      // OSRM expects coordinates in Longitude,Latitude order
      const url = ${this.OSRM_API_URL}/,;,?overview=full&alternatives=true;
      
      const response = await lastValueFrom(
        this.httpService.get(url)
      );

      const routes = response.data.routes;
      if (!routes || routes.length === 0) {
        throw new Error('No routes found');
      }

      return {
        routes: routes.map((r: any, index: number) => ({
          id: 'route-' + index,
          distanceMeters: r.distance, // OSRM returns distance in meters
          duration: r.duration + 's', // Match the old Google format "123s" for compatibility with NavigationService
          polyline: r.geometry, // OSRM returns polyline5 string directly in geometry
          legs: r.legs
        }))
      };
    } catch (error: any) {
      this.logger.error('Failed to calculate route via OSRM: ' + error.message);
      throw new Error('Routing failed. Please try again later.');
    }
  }
}
