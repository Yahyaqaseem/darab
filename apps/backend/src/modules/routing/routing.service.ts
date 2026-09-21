import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';

@Injectable()
export class RoutingService {
  private readonly logger = new Logger(RoutingService.name);
  private readonly GOOGLE_ROUTES_API_URL = 'https://routes.googleapis.com/directions/v2:computeRoutes';
  private readonly API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'MISSING_KEY';

  constructor(private readonly httpService: HttpService) {}

  async calculateRoute(originLat: number, originLng: number, destLat: number, destLng: number) {
    try {
      if (this.API_KEY === 'MISSING_KEY' || this.API_KEY === '') {
        this.logger.warn('Google Maps API Key is missing. Returning an honest empty state/error.');
        throw new Error('Routing service is currently unavailable (Missing API Key)');
      }

      const requestBody = {
        origin: { location: { latLng: { latitude: originLat, longitude: originLng } } },
        destination: { location: { latLng: { latitude: destLat, longitude: destLng } } },
        travelMode: 'DRIVE',
        routingPreference: 'TRAFFIC_AWARE',
        computeAlternativeRoutes: true,
        routeModifiers: { avoidTolls: false, avoidHighways: false, avoidFerries: true },
        languageCode: 'ar'
      };

      const headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': this.API_KEY,
        'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs'
      };

      const response = await lastValueFrom(
        this.httpService.post(this.GOOGLE_ROUTES_API_URL, requestBody, { headers })
      );

      const routes = response.data.routes;
      if (!routes || routes.length === 0) {
        throw new Error('No routes found');
      }

      return {
        routes: routes.map((r: any, index: number) => ({
          id: 'route-' + index,
          distanceMeters: r.distanceMeters,
          duration: r.duration,
          polyline: r.polyline.encodedPolyline,
          legs: r.legs
        }))
      };
    } catch (error: any) {
      this.logger.error('Failed to calculate route: ' + error.message);
      throw new Error('Routing failed. Please try again later.');
    }
  }
}
