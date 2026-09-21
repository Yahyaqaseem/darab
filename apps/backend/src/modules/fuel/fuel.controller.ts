import { Controller, Get, Post, Body, Param, Query, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiBearerAuth } from '@nestjs/swagger';
import { FuelService } from './fuel.service';
import { UpdateFuelReportDto } from './dto/fuel.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('محطات الوقود والأسعار (Fuel Stations)')
@Controller('fuel')
export class FuelController {
  constructor(private readonly fuelService: FuelService) {}

  @Get('nearby')
  @ApiOperation({ summary: 'جلب محطات الوقود القريبة مع الأسعار الحية والازدحام' })
  @ApiQuery({ name: 'lat', required: true, type: Number, example: 36.191113 })
  @ApiQuery({ name: 'lng', required: true, type: Number, example: 44.009167 })
  @ApiQuery({ name: 'radius', required: false, type: Number, example: 25000 })
  async getNearbyFuelStations(
    @Query('lat') lat: number,
    @Query('lng') lng: number,
    @Query('radius') radius?: number,
  ) {
    return this.fuelService.getNearbyFuelStations(Number(lat), Number(lng), radius ? Number(radius) : 25000);
  }

  @Post(':id/report')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'تحديث سعر الوقود أو التوفر أو مستوى الازدحام' })
  async updateFuelStation(
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: UpdateFuelReportDto,
  ) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.fuelService.updateFuelStation(id, userId, dto);
  }
}
