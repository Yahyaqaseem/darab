import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { NavigationService } from './navigation.service';
import { CalculateRouteDto } from './dto/navigation.dto';

@ApiTags('الملاحة وتوجيه المسارات (Smart Navigation)')
@Controller('navigation')
export class NavigationController {
  constructor(private readonly navigationService: NavigationService) {}

  @Post('calculate-routes')
  @ApiOperation({ summary: 'حساب المسارات ومقارنة جودتها وسلامتها بناءً على تقارير السائقين' })
  async calculateRoutes(@Body() dto: CalculateRouteDto) {
    return this.navigationService.calculateRoutes(dto);
  }
}
