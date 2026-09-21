import { Injectable, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';

@Injectable()
export class GamificationService {
  private readonly logger = new Logger(GamificationService.name);

  constructor(private readonly db: DatabaseService) {}

  async getLeaderboard() {
    return [
      { rank: 1, username: 'صقر_طريق_الموصل', trustLevel: 'ROAD_LEGEND', reputationScore: 1240, verifiedReports: 142 },
      { rank: 2, username: 'سائق_أربيل_الخبير', trustLevel: 'ROAD_EXPERT', reputationScore: 890, verifiedReports: 94 },
      { rank: 3, username: 'كابتن_طريق_الجنوب', trustLevel: 'CITY_EYE', reputationScore: 780, verifiedReports: 81 },
      { rank: 4, username: 'درب_بغداد', trustLevel: 'CITY_EYE', reputationScore: 650, verifiedReports: 67 },
      { rank: 5, username: 'رحال_كردستان', trustLevel: 'EXPLORER', reputationScore: 420, verifiedReports: 45 },
    ];
  }

  async getAllBadges() {
    return [
      {
        slug: 'eye_of_erbil',
        titleAr: 'عين أربيل',
        titleEn: 'Eye of Erbil',
        descriptionAr: 'أكثر من 20 بلاغ دقيق ومؤكد في أربيل وضواحيها',
        icon: 'visibility',
        requiredPoints: 50,
      },
      {
        slug: 'road_expert',
        titleAr: 'خبير الطرق',
        titleEn: 'Road Expert',
        descriptionAr: 'المساهمة في تأكيد 50 بلاغاً والإجابة على نداء الطريق',
        icon: 'verified',
        requiredPoints: 150,
      },
      {
        slug: 'travel_king',
        titleAr: 'ملك السفر',
        titleEn: 'Travel King',
        descriptionAr: 'قطع أكثر من 1,000 كم على الطرق السريعة بين المحافظات',
        icon: 'navigation',
        requiredPoints: 300,
      },
      {
        slug: 'iraq_explorer',
        titleAr: 'مستكشف العراق',
        titleEn: 'Iraq Explorer',
        descriptionAr: 'القيادة والإبلاغ في أكثر من 4 محافظات عراقية مختلفة',
        icon: 'public',
        requiredPoints: 600,
      },
    ];
  }
}
