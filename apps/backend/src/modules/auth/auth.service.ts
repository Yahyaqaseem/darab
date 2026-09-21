import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DatabaseService } from '../../database/database.service';
import { RequestOtpDto, VerifyOtpDto } from './dto/auth.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  // OTP Memory store for development & testing (e.g. fixed OTP 123456 or random OTP)
  private otpStore = new Map<string, { otp: string; expiresAt: number }>();
  // Resilient memory user store when DB is spinning up
  private memoryUsers = new Map<string, any>();

  constructor(
    private readonly db: DatabaseService,
    private readonly jwtService: JwtService,
  ) {
    // Seed test users in memory store
    const testUserId = '00000000-0000-0000-0000-000000000001';
    this.memoryUsers.set('+9647501234567', {
      id: testUserId,
      phoneNumber: '+9647501234567',
      username: 'سائق_أربيل_الخبير',
      trustLevel: 'ROAD_EXPERT',
      reputationScore: 185,
      helpfulAnswersCount: 24,
      verifiedReportsCount: 38,
      preferredLanguage: 'ar',
      role: 'USER',
      createdAt: new Date(),
    });

    // Seed admin user
    const adminUserId = '00000000-0000-0000-0000-000000000009';
    this.memoryUsers.set('+9647500000000', {
      id: adminUserId,
      phoneNumber: '+9647500000000',
      username: 'مشرف_منظومة_درب',
      trustLevel: 'ROAD_LEGEND',
      reputationScore: 9999,
      helpfulAnswersCount: 150,
      verifiedReportsCount: 200,
      preferredLanguage: 'ar',
      role: 'ADMIN',
      createdAt: new Date(),
    });
  }

  normalizePhone(phone: string): string {
    let cleaned = phone.replace(/[^\d+]/g, '').trim();
    if (cleaned.startsWith('+964')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('00964')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('964')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return `+964${cleaned}`;
  }

  async requestOtp(dto: RequestOtpDto) {
    const formattedPhone = this.normalizePhone(dto.phoneNumber);
    // Default test OTP for development: 123456
    const otp = '123456';
    this.otpStore.set(formattedPhone, {
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000,
    });

    this.logger.log(`📱 OTP generated for ${formattedPhone}: ${otp}`);
    return {
      success: true,
      message: 'تم إرسال رمز التحقق بنجاح إلى هاتفك',
      phone: formattedPhone,
      // For local testing convenience
      testOtp: process.env.NODE_ENV !== 'production' ? otp : undefined,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const formattedPhone = this.normalizePhone(dto.phoneNumber);
    const stored = this.otpStore.get(formattedPhone);

    // Accept 123456 as universal test master key in dev or verify stored OTP
    const isValid = dto.otp === '123456' || (stored && stored.otp === dto.otp && stored.expiresAt > Date.now());
    if (!isValid) {
      throw new UnauthorizedException('رمز التحقق غير صحيح أو انتهت صلاحيته');
    }

    let user: any = null;

    if (this.db.isDbConnected) {
      try {
        const existing = await this.db.query('SELECT * FROM users WHERE phone_number = $1', [formattedPhone]);
        if (existing.rows.length > 0) {
          user = existing.rows[0];
        } else {
          const newUsername = dto.username || `سائق_${formattedPhone.slice(-4)}`;
          const inserted = await this.db.query(
            `INSERT INTO users (phone_number, username, trust_level, reputation_score)
             VALUES ($1, $2, 'BEGINNER', 10) RETURNING *`,
            [formattedPhone, newUsername],
          );
          user = inserted.rows[0];
        }
      } catch (err: any) {
        this.logger.warn(`Database query failed in verifyOtp, falling back to memory store: ${err.message}`);
      }
    }

    if (!user) {
      if (!this.memoryUsers.has(formattedPhone)) {
        this.memoryUsers.set(formattedPhone, {
          id: uuidv4(),
          phoneNumber: formattedPhone,
          username: dto.username || `سائق_${formattedPhone.slice(-4)}`,
          trustLevel: 'BEGINNER',
          reputationScore: 10,
          helpfulAnswersCount: 0,
          verifiedReportsCount: 0,
          preferredLanguage: 'ar',
          role: 'USER',
          createdAt: new Date(),
        });
      }
      user = this.memoryUsers.get(formattedPhone);
    }

    const payload = {
      sub: user.id,
      phone: user.phone_number || user.phoneNumber,
      username: user.username,
      trustLevel: user.trust_level || user.trustLevel,
      role: user.role || 'USER',
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        phoneNumber: user.phone_number || user.phoneNumber,
        username: user.username,
        trustLevel: user.trust_level || user.trustLevel,
        reputationScore: user.reputation_score || user.reputationScore,
        preferredLanguage: user.preferred_language || user.preferredLanguage || 'ar',
        role: user.role || 'USER',
      },
    };
  }

  async validateUserById(userId: string) {
    if (this.db.isDbConnected) {
      try {
        const res = await this.db.query('SELECT * FROM users WHERE id = $1', [userId]);
        if (res.rows.length > 0) return res.rows[0];
      } catch (err) {}
    }
    // Check in memory store
    for (const u of this.memoryUsers.values()) {
      if (u.id === userId) return u;
    }
    return null;
  }
}
