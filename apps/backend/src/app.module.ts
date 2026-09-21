import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { RealtimeModule } from './modules/realtime/realtime.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ReportsModule } from './modules/reports/reports.module';
import { RoadCallModule } from './modules/road-call/road-call.module';
import { FuelModule } from './modules/fuel/fuel.module';
import { NavigationModule } from './modules/navigation/navigation.module';
import { PlacesModule } from './modules/places/places.module';
import { TripsModule } from './modules/trips/trips.module';
import { GamificationModule } from './modules/gamification/gamification.module';
import { BusinessModule } from './modules/business/business.module';
import { AdminModule } from './modules/admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    DatabaseModule,
    RealtimeModule,
    AuthModule,
    UsersModule,
    ReportsModule,
    RoadCallModule,
    FuelModule,
    NavigationModule,
    PlacesModule,
    TripsModule,
    GamificationModule,
    BusinessModule,
    AdminModule,
  ],
})
export class AppModule {}
