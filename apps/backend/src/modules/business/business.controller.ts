import { Controller, Get, Patch, Body, Param, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { BusinessService } from './business.service';
import { UpdateBusinessInfoDto } from './dto/business.dto';

@ApiTags('لوحة تحكم أصحاب الأنشطة والمحطات (Business Dashboard)')
@Controller('business')
export class BusinessController {
  constructor(private readonly businessService: BusinessService) {}

  @Get('my-business')
  @ApiOperation({ summary: 'جلب بيانات وإحصائيات المحطة أو النشاط التجاري للتاجر' })
  async getMyBusiness(@Req() req: any) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.businessService.getMyBusiness(userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'تحديث بيانات المحطة والأسعار والعروض الترويجية' })
  async updateBusiness(
    @Param('id') id: string,
    @Body() dto: UpdateBusinessInfoDto,
  ) {
    return this.businessService.updateBusiness(id, dto);
  }
}
