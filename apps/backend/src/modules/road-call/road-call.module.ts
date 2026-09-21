import { Module } from '@nestjs/common';
import { RoadCallService } from './road-call.service';
import { RoadCallController } from './road-call.controller';
import { ReportsModule } from '../reports/reports.module';

@Module({
  imports: [ReportsModule],
  controllers: [RoadCallController],
  providers: [RoadCallService],
  exports: [RoadCallService],
})
export class RoadCallModule {}
