import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { CreateReportDto, ConfirmReportDto, ReportType, ReportStatus, ConfirmationVote } from './dto/reports.dto';
import { v4 as uuidv4 } from 'uuid';
import { GeoUtils } from '../../common/utils/geo.utils';

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);
  private memoryReports = new Map<string, any>();

  constructor(
    private readonly db: DatabaseService,
    private readonly realtimeGateway: RealtimeGateway,
  ) {
    this.seedInitialReports();
  }

  private seedInitialReports() {
    // Initial Iraqi road reports in Erbil, Baghdad, Duhok highway
    const sampleReports = [
      {
        id: 'rep-1',
        type: ReportType.HEAVY_TRAFFIC,
        title: 'زحمة شديدة عند سيطرة الكلك',
        description: 'طابور طويل من السيارات قبل السيطرة بمسافة 1.5 كم',
        latitude: 36.2625,
        longitude: 43.6667,
        roadName: 'طريق أربيل - الموصل - دهوك',
        roadSegmentId: 'erbil-duhok-m10',
        bearing: 310,
        confidence: 0.92,
        confirmationsCount: 8,
        rejectionsCount: 1,
        ttlSeconds: 1800,
        status: ReportStatus.CONFIRMED,
        expiresAt: new Date(Date.now() + 25 * 60 * 1000),
        createdAt: new Date(Date.now() - 5 * 60 * 1000),
      },
      {
        id: 'rep-2',
        type: ReportType.ACCIDENT,
        title: 'حادث تصادم على شارع 100 متري',
        description: 'حادث بسيط قرب تقاطع عينكاوة باتجاه المطار، المسار الأيسر متوقف',
        latitude: 36.2167,
        longitude: 44.0089,
        roadName: 'شارع 100 متري - أربيل',
        roadSegmentId: 'erbil-100m',
        bearing: 270,
        confidence: 0.88,
        confirmationsCount: 6,
        rejectionsCount: 0,
        ttlSeconds: 2700,
        status: ReportStatus.CONFIRMED,
        expiresAt: new Date(Date.now() + 35 * 60 * 1000),
        createdAt: new Date(Date.now() - 10 * 60 * 1000),
      },
      {
        id: 'rep-3',
        type: ReportType.CHECKPOINT,
        title: 'نقطة تفتيش نشطة (سيطرة شيراوة)',
        description: 'إجراءات تدقيق هويات سلسة وتأخير لا يتجاوز 5 دقائق',
        latitude: 35.8500,
        longitude: 44.3833,
        roadName: 'طريق كركوك - أربيل',
        roadSegmentId: 'kirkuk-erbil-rd',
        bearing: 340,
        confidence: 0.95,
        confirmationsCount: 12,
        rejectionsCount: 0,
        ttlSeconds: 3600,
        status: ReportStatus.CONFIRMED,
        expiresAt: new Date(Date.now() + 45 * 60 * 1000),
        createdAt: new Date(Date.now() - 15 * 60 * 1000),
      },
      {
        id: 'rep-4',
        type: ReportType.POTHOLE,
        title: 'حفرة وتخسف مفاجئ في الطريق السريع',
        description: 'حفرة عميقة في المسار الأيمن بعد الجسر بـ 500 متر، انتبه!',
        latitude: 33.3152,
        longitude: 44.3661,
        roadName: 'طريق المرور السريع رقم 1 - بغداد',
        roadSegmentId: 'baghdad-highway-1',
        bearing: 180,
        confidence: 0.85,
        confirmationsCount: 5,
        rejectionsCount: 0,
        ttlSeconds: 43200, // 12 hours
        status: ReportStatus.ACTIVE,
        expiresAt: new Date(Date.now() + 10 * 3600 * 1000),
        createdAt: new Date(Date.now() - 2 * 3600 * 1000),
      },
    ];

    for (const r of sampleReports) {
      this.memoryReports.set(r.id, {
        ...r,
        voters: new Set<string>(['00000000-0000-0000-0000-000000000002']),
      });
    }
  }

  onModuleInit() {
    // Start automated decay and cleanup worker every 30 seconds
    setInterval(() => this.runDecayCycle(), 30000);
  }

  /**
   * Periodic confidence decay and expiration cycle
   * C(t) = C_0 * e^(-lambda * (t / TTL))
   */
  async runDecayCycle() {
    const now = Date.now();
    for (const [id, report] of this.memoryReports.entries()) {
      if (report.status === ReportStatus.ACTIVE || report.status === ReportStatus.CONFIRMED) {
        const createdAtTime = new Date(report.createdAt).getTime();
        const elapsedSec = (now - createdAtTime) / 1000;
        const ttlSec = report.ttlSeconds || 1800;

        if (now > new Date(report.expiresAt).getTime()) {
          report.status = ReportStatus.EXPIRED;
          report.confidence = 0.05;
        } else {
          // Decay lambda = 1.2
          const progress = elapsedSec / ttlSec;
          const initialConfidence = report.status === ReportStatus.CONFIRMED ? 0.9 : 0.6;
          const decayed = initialConfidence * Math.exp(-1.2 * progress);
          report.confidence = Math.max(0.1, Math.round(decayed * 100) / 100);
        }
      }
    }

    if (this.db.isDbConnected) {
      try {
        await this.db.query(`
          UPDATE road_reports 
          SET status = 'EXPIRED', confidence = 0.05, updated_at = NOW()
          WHERE expires_at <= NOW() AND status IN ('ACTIVE', 'CONFIRMED')
        `);
      } catch (err: any) {
        this.logger.debug(`Decay cycle DB update: ${err.message}`);
      }
    }
  }

  private calculateTtlSeconds(type: ReportType): number {
    switch (type) {
      case ReportType.HEAVY_TRAFFIC:
        return 20 * 60; // 20 mins
      case ReportType.ACCIDENT:
      case ReportType.BROKEN_CAR:
        return 45 * 60; // 45 mins
      case ReportType.CHECKPOINT:
      case ReportType.DETOUR:
        return 60 * 60; // 1 hour
      case ReportType.ROAD_WORK:
      case ReportType.CLOSURE:
        return 120 * 60; // 2 hours
      case ReportType.POTHOLE:
      case ReportType.HAZARD:
      case ReportType.WATER_ACCUMULATION:
        return 12 * 3600; // 12 hours
      default:
        return 30 * 60;
    }
  }

  private userLastReportTime = new Map<string, number>();

  async createReport(userId: string, dto: CreateReportDto) {
    const now = Date.now();

    // 1. Anti-Spam Rate Limiting: max 1 report per 30 seconds per user
    const lastReport = this.userLastReportTime.get(userId);
    if (lastReport && now - lastReport < 25000) {
      const waitSeconds = Math.ceil((25000 - (now - lastReport)) / 1000);
      return {
        success: false,
        isRateLimited: true,
        message: `يرجى الانتظار ${waitSeconds} ثوانٍ قبل إرسال بلاغ جديد لمنع التكرار أثناء القيادة`,
      };
    }
    this.userLastReportTime.set(userId, now);

    // 2. Spatial Duplicate Detection: if report of same type is within 250m, merge as confirmation
    for (const existing of this.memoryReports.values()) {
      if (existing.status === ReportStatus.ACTIVE || existing.status === ReportStatus.CONFIRMED) {
        if (existing.type === dto.type) {
          const dist = GeoUtils.haversineDistance(dto.latitude, dto.longitude, existing.latitude, existing.longitude);
          if (dist <= 250) {
            this.logger.log(`Duplicate report merged into existing incident ${existing.id} (${Math.round(dist)}m away)`);
            return this.confirmReport(existing.id, userId, {
              vote: ConfirmationVote.CONFIRM,
              userLatitude: dto.latitude,
              userLongitude: dto.longitude,
            });
          }
        }
      }
    }

    const ttlSeconds = this.calculateTtlSeconds(dto.type);
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);
    const id = uuidv4();

    let title = '';
    switch (dto.type) {
      case ReportType.ACCIDENT:
        title = 'حادث سير';
        break;
      case ReportType.HEAVY_TRAFFIC:
        title = 'ازدحام مروري';
        break;
      case ReportType.CLOSURE:
        title = 'طريق مغلق';
        break;
      case ReportType.CHECKPOINT:
        title = 'سيطرة / نقطة تفتيش';
        break;
      case ReportType.POTHOLE:
        title = 'حفرة / تخسف';
        break;
      case ReportType.HAZARD:
        title = 'خطر على الطريق';
        break;
      case ReportType.WATER_ACCUMULATION:
        title = 'تجمع مياه / فيضان';
        break;
      case ReportType.DETOUR:
        title = 'تحويلة طريق';
        break;
      case ReportType.ROAD_WORK:
        title = 'أعمال صيانة الطريق';
        break;
      default:
        title = 'تنبيه على الطريق';
    }

    const newReport = {
      id,
      userId,
      type: dto.type,
      title: dto.roadName ? `${title} (${dto.roadName})` : title,
      description: dto.description || '',
      latitude: dto.latitude,
      longitude: dto.longitude,
      roadName: dto.roadName || 'طريق عام',
      roadSegmentId: dto.roadSegmentId || 'default-segment',
      bearing: dto.bearing,
      confidence: 0.65,
      confirmationsCount: 1,
      rejectionsCount: 0,
      ttlSeconds,
      status: ReportStatus.ACTIVE,
      expiresAt,
      createdAt: new Date(),
      updatedAt: new Date(),
      voters: new Set<string>([userId]),
    };

    if (this.db.isDbConnected) {
      try {
        await this.db.query(
          `INSERT INTO road_reports 
           (id, user_id, type, title, description, location, latitude, longitude, road_name, road_segment_id, bearing, confidence, ttl_seconds, status, expires_at)
           VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326), $7, $6, $8, $9, $10, 0.65, $11, 'ACTIVE', $12)`,
          [
            id,
            userId,
            dto.type,
            newReport.title,
            newReport.description,
            dto.longitude,
            dto.latitude,
            newReport.roadName,
            newReport.roadSegmentId,
            dto.bearing,
            ttlSeconds,
            expiresAt,
          ],
        );
      } catch (err: any) {
        this.logger.warn(`Failed to insert report into DB: ${err.message}`);
      }
    }

    this.memoryReports.set(id, newReport);
    this.realtimeGateway.broadcastNewReport(newReport);

    return newReport;
  }

  async getNearbyReports(lat: number, lng: number, radiusMeters: number = 30000) {
    if (this.db.isDbConnected) {
      try {
        const res = await this.db.query(
          `SELECT id, user_id as "userId", type, title, description, latitude, longitude, 
                  road_name as "roadName", road_segment_id as "roadSegmentId", bearing, 
                  confidence, confirmations_count as "confirmationsCount", rejections_count as "rejectionsCount",
                  status, expires_at as "expiresAt", created_at as "createdAt",
                  ST_Distance(location::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) as "distanceMeters"
           FROM road_reports
           WHERE expires_at > NOW() AND status IN ('ACTIVE', 'CONFIRMED')
             AND ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3)
           ORDER BY "distanceMeters" ASC`,
          [lng, lat, radiusMeters],
        );
        if (res.rows.length > 0) return res.rows;
      } catch (err: any) {
        this.logger.warn(`PostGIS query failed in getNearbyReports: ${err.message}`);
      }
    }

    // Memory spatial search fallback with live decay check
    const results: any[] = [];
    const now = Date.now();
    for (const report of this.memoryReports.values()) {
      if (new Date(report.expiresAt).getTime() > now && report.status !== ReportStatus.EXPIRED && report.status !== ReportStatus.RESOLVED) {
        const dist = GeoUtils.haversineDistance(lat, lng, report.latitude, report.longitude);
        if (dist <= radiusMeters) {
          results.push({
            ...report,
            distanceMeters: Math.round(dist),
          });
        }
      }
    }

    return results.sort((a, b) => a.distanceMeters - b.distanceMeters);
  }

  async confirmReport(reportId: string, userId: string, dto: ConfirmReportDto) {
    let report = this.memoryReports.get(reportId);

    if (this.db.isDbConnected) {
      try {
        const res = await this.db.query('SELECT * FROM road_reports WHERE id = $1', [reportId]);
        if (res.rows.length > 0) report = res.rows[0];
      } catch (err) {}
    }

    if (!report) {
      throw new NotFoundException('البلاغ غير موجود أو انتهت صلاحيته');
    }

    // Initialize voter tracking set
    if (!report.voters) {
      report.voters = new Set<string>();
    }

    // Prevent duplicate voting from same user
    if (report.voters.has(userId)) {
      return {
        success: true,
        message: 'لقد قمت بالتصويت على هذا البلاغ مسبقاً',
        alreadyVoted: true,
        report,
      };
    }
    report.voters.add(userId);

    // Validate proximity if user coordinates provided (must be within 30km of incident)
    if (dto.userLatitude !== undefined && dto.userLongitude !== undefined) {
      const dist = GeoUtils.haversineDistance(dto.userLatitude, dto.userLongitude, report.latitude, report.longitude);
      if (dist > 35000) {
        // Driver is too far away to give credible live report confirmation
        return {
          success: false,
          message: 'أنت بعيد جداً عن موقع البلاغ لتأكيد حالته الميدانية',
          report,
        };
      }
    }

    if (dto.vote === ConfirmationVote.CONFIRM) {
      report.confirmationsCount = (report.confirmationsCount || report.confirmations_count || 0) + 1;
      report.confidence = Math.min(0.99, (report.confidence || 0.5) + 0.12);
      if (report.confirmationsCount >= 2) {
        report.status = ReportStatus.CONFIRMED;
      }
    } else if (dto.vote === ConfirmationVote.NOT_THERE_ANYMORE) {
      report.rejectionsCount = (report.rejectionsCount || report.rejections_count || 0) + 1;
      report.confidence = Math.max(0.1, (report.confidence || 0.5) - 0.25);
      if (report.rejectionsCount >= 3 || report.confidence < 0.25) {
        report.status = ReportStatus.RESOLVED;
      }
    }

    if (this.db.isDbConnected) {
      try {
        await this.db.query(
          `UPDATE road_reports 
           SET confirmations_count = $1, rejections_count = $2, confidence = $3, status = $4, updated_at = NOW()
           WHERE id = $5`,
          [report.confirmationsCount, report.rejectionsCount, report.confidence, report.status, reportId],
        );
      } catch (err) {}
    }

    this.memoryReports.set(reportId, report);
    this.realtimeGateway.broadcastReportConfirmation({
      reportId,
      vote: dto.vote,
      confirmationsCount: report.confirmationsCount,
      rejectionsCount: report.rejectionsCount,
      status: report.status,
    });

    return {
      success: true,
      message: dto.vote === ConfirmationVote.CONFIRM ? 'شكراً لك! تم تأكيد البلاغ ورفع درجة الموثوقية' : 'تم استلام ملاحظتك وتحديث حالة الطريق',
      report,
    };
  }
}
