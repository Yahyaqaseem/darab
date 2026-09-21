import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { UpdateBusinessInfoDto } from './dto/business.dto';

@Injectable()
export class BusinessService {
  private readonly logger = new Logger(BusinessService.name);
  private businesses = new Map<string, any>();

  constructor(private readonly db: DatabaseService) {
    
  }

  private seedDemoBusinesses() {
    this.businesses.set('biz-1', {
      id: 'biz-1',
      ownerUserId: '00000000-0000-0000-0000-000000000001',
      businessType: 'FUEL_STATION',
      name: 'محطة وقود كوردستان 100 متري',
      phone: '+9647501239991',
      openingHours: '24 ساعة',
      petrolPrice: 850,
      premiumPrice: 1150,
      dieselPrice: 750,
      isAvailable: true,
      specialOffer: 'خصم 15% على غسيل السيارات الكامل عند التعبئة بأكثر من 40,000 د.ع',
      analytics: {
        viewsCount: 4280,
        directionClicks: 1120,
        directCalls: 340,
        savesCount: 185,
        offerClicks: 490,
      },
      updatedAt: new Date(),
    });
  }

  async getMyBusiness(userId: string) {
    for (const b of this.businesses.values()) {
      if (b.ownerUserId === userId) return b;
    }
    return this.businesses.get('biz-1');
  }

  async updateBusiness(businessId: string, dto: UpdateBusinessInfoDto) {
    let biz = this.businesses.get(businessId);
    if (!biz) {
      biz = this.businesses.get('biz-1');
    }

    Object.assign(biz, dto, { updatedAt: new Date() });
    this.businesses.set(businessId, biz);

    return {
      success: true,
      message: 'تم تحديث بيانات المحطة/النشاط التجاري والعرض الترويجي بنجاح!',
      business: biz,
    };
  }
}
