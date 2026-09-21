import { Module } from '@nestjs/common';
import { NavigationService } from './navigation.service';
import { RoutingModule } from '../routing/routing.module';
import { NavigationController } from './navigation.controller';
import { ReportsModule } from '../reports/reports.module';

@Module({
  imports: [ReportsModule, RoutingModule],
  controllers: [NavigationController],
  providers: [NavigationService],
  exports: [NavigationService],
})
export class NavigationModule {}
