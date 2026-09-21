import { Controller, Get, Post, Body, Param, Query, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiBearerAuth } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { CreateReportDto, ConfirmReportDto } from './dto/reports.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('بلاغات الطرق الحية (Road Reports)')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('nearby')
  @ApiOperation({ summary: 'جلب بلاغات الطرق الحية القريبة من موقع السائق' })
  @ApiQuery({ name: 'lat', required: true, type: Number, example: 36.191113 })
  @ApiQuery({ name: 'lng', required: true, type: Number, example: 44.009167 })
  @ApiQuery({ name: 'radius', required: false, type: Number, example: 30000, description: 'نصف القطر بالمتر' })
  async getNearbyReports(
    @Query('lat') lat: number,
    @Query('lng') lng: number,
    @Query('radius') radius?: number,
  ) {
    return this.reportsService.getNearbyReports(Number(lat), Number(lng), radius ? Number(radius) : 30000);
  }

  @Post()
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'إنشاء بلاغ طريق فوري بضغطة واحدة (حادث، زحمة، سيطرة، حفرة...)' })
  async createReport(@Req() req: any, @Body() dto: CreateReportDto) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.reportsService.createReport(userId, dto);
  }

  @Post(':id/confirm')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'تأكيد أو نفي بلاغ من السائقين في الموقع' })
  async confirmReport(
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: ConfirmReportDto,
  ) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.reportsService.confirmReport(id, userId, dto);
  }
}
