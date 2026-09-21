import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { GamificationService } from './gamification.service';

@ApiTags('السمعة والأوسمة (Gamification & Badges)')
@Controller('gamification')
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Get('leaderboard')
  @ApiOperation({ summary: 'لوحة شرف أفضل السائقين المساهمين في العراق' })
  async getLeaderboard() {
    return this.gamificationService.getLeaderboard();
  }

  @Get('badges')
  @ApiOperation({ summary: 'قائمة الأوسمة وشروط الحصول عليها' })
  async getBadges() {
    return this.gamificationService.getAllBadges();
  }
}
