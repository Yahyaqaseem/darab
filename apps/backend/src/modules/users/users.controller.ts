import { Controller, Get, Patch, Post, Body, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateProfileDto, CreateVehicleDto } from './dto/user.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('المستخدمين والمرآب (Users & Garage)')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'جلب الملف الشخصي والسمعة والمرآب' })
  async getProfile(@Req() req: any) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.usersService.getProfile(userId);
  }

  @Patch('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'تحديث بيانات المستخدم واللغة' })
  async updateProfile(@Req() req: any, @Body() dto: UpdateProfileDto) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.usersService.updateProfile(userId, dto);
  }

  @Post('vehicles')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'إضافة سيارة جديدة لمرآب السائق' })
  async addVehicle(@Req() req: any, @Body() dto: CreateVehicleDto) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    return this.usersService.addVehicle(userId, dto);
  }
}
