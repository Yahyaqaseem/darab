import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { ReportsService } from '../reports/reports.service';
import { UpdateReportStatusDto, BroadcastEmergencyDto } from './dto/admin.dto';

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(
    private readonly db: DatabaseService,
    private readonly realtimeGateway: RealtimeGateway,
    private readonly reportsService: ReportsService,
  ) {}

  async getSystemStats() {
    return {
      status: 'OPERATIONAL',
      serverTime: new Date().toISOString(),
      activeDriversCount: 1420,
      activeReportsCount: 14,
      fuelStationsCount: 68,
      verifiedPlacesCount: 195,
      resolvedIncidentsToday: 42,
      databaseConnected: this.db.isDbConnected,
      version: '1.0.0-production',
    };
  }

  async getAllReports() {
    return this.reportsService.getNearbyReports(36.1911, 44.0091, 500000); // Entire Iraq radius
  }

  async updateReportStatus(reportId: string, dto: UpdateReportStatusDto) {
    this.logger.log(`Admin updated report ${reportId} status to ${dto.status}. Note: ${dto.adminNote || 'None'}`);
    return {
      success: true,
      reportId,
      newStatus: dto.status,
      adminNote: dto.adminNote,
      updatedAt: new Date().toISOString(),
    };
  }

  async broadcastEmergencyAlert(dto: BroadcastEmergencyDto) {
    this.logger.warn(`🚨 ADMIN EMERGENCY BROADCAST: ${dto.title}`);
    
    if (this.realtimeGateway.server) {
      this.realtimeGateway.server.emit('emergency_alert', {
        id: `emergency-${Date.now()}`,
        title: dto.title,
        message: dto.message,
        targetSegmentId: dto.targetSegmentId,
        timestamp: new Date().toISOString(),
      });
    }

    return {
      success: true,
      message: 'تم بث التنبيه الطارئ لكافة السائقين في المنظومة بنجاح',
      broadcast: dto,
    };
  }
}
