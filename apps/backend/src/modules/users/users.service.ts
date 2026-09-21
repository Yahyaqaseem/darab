import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { UpdateProfileDto, CreateVehicleDto } from './dto/user.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private memoryVehicles = new Map<string, any[]>();

  constructor(private readonly db: DatabaseService) {
    // Initial demo vehicles
    const defaultUserId = '00000000-0000-0000-0000-000000000001';
    this.memoryVehicles.set(defaultUserId, [
      {
        id: 'v-1',
        userId: defaultUserId,
        make: 'Toyota',
        model: 'Land Cruiser',
        year: 2023,
        fuelType: 'PETROL',
        isPrimary: true,
        createdAt: new Date(),
      },
      {
        id: 'v-2',
        userId: defaultUserId,
        make: 'Kia',
        model: 'Sportage',
        year: 2021,
        fuelType: 'PETROL',
        isPrimary: false,
        createdAt: new Date(),
      },
    ]);
  }

  async getProfile(userId: string) {
    let user: any = null;
    let vehicles: any[] = [];
    let badges: any[] = [];

    if (this.db.isDbConnected) {
      try {
        const userRes = await this.db.query('SELECT * FROM users WHERE id = $1', [userId]);
        if (userRes.rows.length > 0) {
          user = userRes.rows[0];
          const vehRes = await this.db.query('SELECT * FROM vehicles WHERE user_id = $1 ORDER BY is_primary DESC', [userId]);
          vehicles = vehRes.rows;
          const badgeRes = await this.db.query(
            `SELECT b.*, ub.unlocked_at FROM badges b 
             INNER JOIN user_badges ub ON b.id = ub.badge_id 
             WHERE ub.user_id = $1`,
            [userId],
          );
          badges = badgeRes.rows;
        }
      } catch (err: any) {
        this.logger.warn(`Failed to fetch profile from database: ${err.message}`);
      }
    }

    if (!user) {
      // Memory fallback
      user = {
        id: userId,
        phoneNumber: '+9647501234567',
        username: 'سائق_أربيل_الخبير',
        trustLevel: 'ROAD_EXPERT',
        reputationScore: 0,
        helpfulAnswersCount: 24,
        verifiedReportsCount: 38,
        falseReportsCount: 0,
        preferredLanguage: 'ar',
      };
      vehicles = this.memoryVehicles.get(userId) || [];
      badges = [
        {
          slug: 'eye_of_erbil',
          titleAr: 'عين أربيل',
          titleEn: 'Eye of Erbil',
          descriptionAr: 'أكثر من 20 بلاغ دقيق ومؤكد في أربيل وضواحيها',
          icon: 'visibility',
          unlockedAt: new Date(Date.now() - 7 * 24 * 3600 * 1000),
        },
        {
          slug: 'road_expert',
          titleAr: 'خبير الطرق',
          titleEn: 'Road Expert',
          descriptionAr: 'المساهمة في تأكيد 50 بلاغاً والإجابة على نداء الطريق',
          icon: 'verified',
          unlockedAt: new Date(Date.now() - 2 * 24 * 3600 * 1000),
        },
      ];
    }

    return {
      user,
      vehicles,
      badges,
      stats: {
        totalDistanceKm: 1450.5,
        totalTripsCount: 42,
        pointsToNextLevel: 115,
        nextLevelTitle: 'عين المدينة (City Eye)',
      },
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    if (this.db.isDbConnected) {
      try {
        const res = await this.db.query(
          `UPDATE users 
           SET username = COALESCE($1, username),
               preferred_language = COALESCE($2, preferred_language),
               fcm_token = COALESCE($3, fcm_token),
               updated_at = NOW()
           WHERE id = $4 RETURNING *`,
          [dto.username, dto.preferredLanguage, dto.fcmToken, userId],
        );
        if (res.rows.length > 0) return res.rows[0];
      } catch (err) {}
    }
    return { id: userId, ...dto, updatedAt: new Date() };
  }

  async addVehicle(userId: string, dto: CreateVehicleDto) {
    if (this.db.isDbConnected) {
      try {
        if (dto.isPrimary) {
          await this.db.query('UPDATE vehicles SET is_primary = FALSE WHERE user_id = $1', [userId]);
        }
        const res = await this.db.query(
          `INSERT INTO vehicles (user_id, make, model, year, fuel_type, is_primary)
           VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
          [userId, dto.make, dto.model, dto.year, dto.fuelType || 'PETROL', dto.isPrimary || false],
        );
        return res.rows[0];
      } catch (err) {}
    }

    const newVehicle = {
      id: uuidv4(),
      userId,
      ...dto,
      createdAt: new Date(),
    };
    const list = this.memoryVehicles.get(userId) || [];
    list.push(newVehicle);
    this.memoryVehicles.set(userId, list);
    return newVehicle;
  }
}
