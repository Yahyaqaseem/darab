import { Controller, Get, Post, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { AdminService } from './admin.service';
import { UpdateReportStatusDto, BroadcastEmergencyDto } from './dto/admin.dto';

@ApiTags('لوحة تحكم المشرفين والعمليات (Admin Dashboard)')
@Controller('admin')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('ADMIN')
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'إحصائيات المنظومة الحية وحالة السائقين والعمليات' })
  async getSystemStats() {
    return this.adminService.getSystemStats();
  }

  @Get('reports')
  @ApiOperation({ summary: 'استعراض كافة البلاغات الميدانية الحالية للتدقيق' })
  async getAllReports() {
    return this.adminService.getAllReports();
  }

  @Patch('reports/:id/status')
  @ApiOperation({ summary: 'تحديث أو إغلاق بلاغ يدوياً من قبل إدارة العمليات' })
  async updateReportStatus(
    @Param('id') id: string,
    @Body() dto: UpdateReportStatusDto,
  ) {
    return this.adminService.updateReportStatus(id, dto);
  }

  @Post('broadcast')
  @ApiOperation({ summary: 'بث تنبيه طارئ فوري لجميع السائقين على الطرق' })
  async broadcastEmergencyAlert(@Body() dto: BroadcastEmergencyDto) {
    return this.adminService.broadcastEmergencyAlert(dto);
  }
}
