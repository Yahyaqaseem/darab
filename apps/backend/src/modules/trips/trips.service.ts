import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { CreateTripDto } from './dto/trips.dto';
import { GeoUtils } from '../../common/utils/geo.utils';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class TripsService {
  private readonly logger = new Logger(TripsService.name);
  private memoryTrips = new Map<string, any>();

  constructor(private readonly db: DatabaseService) {
    this.seedDemoTrips();
  }

  private seedDemoTrips() {
    const demoTrip = {
      id: 'trip-demo-1',
      userId: '00000000-0000-0000-0000-000000000001',
      startLatitude: 36.1911,
      startLongitude: 44.0091,
      startName: 'أربيل - بارك شاندر',
      endLatitude: 36.8679,
      endLongitude: 42.9904,
      endName: 'دهوك - المركز',
      distanceKm: 155.4,
      durationSeconds: 8280, // 2h 18m
      durationFormatted: '2 ساعة و 18 دقيقة',
      avgSpeedKmh: 67.5,
      trustedMaxSpeedKmh: 124.0, // After filtering a 250 km/h anomaly
      rawGpsMaxSpeedKmh: 250.0,
      hasAnomalyFiltered: true,
      stopsCount: 1,
      trafficDelaySeconds: 480, // 8 minutes
      createdAt: new Date(Date.now() - 24 * 3600 * 1000),
    };
    this.memoryTrips.set(demoTrip.id, demoTrip);
  }

  async createTrip(userId: string, dto: CreateTripDto) {
    // 1. Calculate trusted max speed and average speed eliminating GPS spikes
    const { trustedMaxSpeed, averageSpeed } = GeoUtils.calculateTrustedMaxSpeed(dto.speedReadings);
    const rawMaxSpeed = Math.max(...(dto.speedReadings || [0]));
    const hasAnomalyFiltered = rawMaxSpeed > trustedMaxSpeed + 30;

    const id = uuidv4();
    const hours = Math.floor(dto.durationSeconds / 3600);
    const mins = Math.floor((dto.durationSeconds % 3600) / 60);

    const tripRecord = {
      id,
      userId,
      startLatitude: dto.startLat,
      startLongitude: dto.startLng,
      startName: dto.startName || 'نقطة الانطلاق',
      endLatitude: dto.endLat,
      endLongitude: dto.endLng,
      endName: dto.endName || 'الوجهة',
      distanceKm: dto.distanceKm,
      durationSeconds: dto.durationSeconds,
      durationFormatted: hours > 0 ? `${hours} ساعة و ${mins} دقيقة` : `${mins} دقيقة`,
      avgSpeedKmh: averageSpeed,
      trustedMaxSpeedKmh: trustedMaxSpeed,
      rawGpsMaxSpeedKmh: rawMaxSpeed,
      hasAnomalyFiltered,
      stopsCount: dto.stopsCount || 0,
      trafficDelaySeconds: dto.trafficDelaySeconds || 0,
      createdAt: new Date(),
    };

    if (this.db.isDbConnected) {
      try {
        await this.db.query(
          `INSERT INTO trips 
           (id, user_id, start_latitude, start_longitude, start_name, end_latitude, end_longitude, end_name, distance_km, duration_seconds, avg_speed_kmh, trusted_max_speed_kmh, stops_count, traffic_delay_seconds)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
          [
            id,
            userId,
            dto.startLat,
            dto.startLng,
            tripRecord.startName,
            dto.endLat,
            dto.endLng,
            tripRecord.endName,
            dto.distanceKm,
            dto.durationSeconds,
            averageSpeed,
            trustedMaxSpeed,
            tripRecord.stopsCount,
            tripRecord.trafficDelaySeconds,
          ],
        );
      } catch (err: any) {
        this.logger.warn(`Failed to insert trip to DB: ${err.message}`);
      }
    }

    this.memoryTrips.set(id, tripRecord);

    return {
      success: true,
      message: 'تم حفظ ملخص الرحلة بنجاح!',
      summary: tripRecord,
    };
  }

  async getUserTrips(userId: string) {
    const list: any[] = [];
    for (const t of this.memoryTrips.values()) {
      if (t.userId === userId) {
        list.push(t);
      }
    }
    return list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  async getTripById(id: string) {
    const trip = this.memoryTrips.get(id);
    if (!trip) throw new NotFoundException('الرحلة غير موجودة');
    return trip;
  }
}
