import { Controller, Get, Post, Body, Param, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TripsService } from './trips.service';
import { CreateTripDto } from './dto/trips.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('الرحلات وإحصائيات القيادة (Trips & Statistics)')
@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post()
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'حفظ ملخص الرحلة بعد الوصول واحتساب السرعة الموثوقة' })
  async createTrip(@Req() req: any, @Body() dto: CreateTripDto) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.tripsService.createTrip(userId, dto);
  }

  @Get()
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'جلب سجل رحلات المستخدم' })
  async getUserTrips(@Req() req: any) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.tripsService.getUserTrips(userId);
  }

  @Get(':id')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'جلب تفاصيل رحلة محددة مع إمكانية الـ Replay' })
  async getTripById(@Param('id') id: string) {
    return this.tripsService.getTripById(id);
  }
}
