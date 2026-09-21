import { IsNotEmpty, IsString, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReportStatus } from '../../reports/dto/reports.dto';

export class UpdateReportStatusDto {
  @ApiProperty({ enum: ReportStatus, example: ReportStatus.RESOLVED })
  @IsEnum(ReportStatus)
  @IsNotEmpty()
  status: ReportStatus;

  @ApiPropertyOptional({ example: 'تم إغلاق البلاغ يدوياً من الإدارة بعد التأكد من زوال الحادث' })
  @IsOptional()
  @IsString()
  adminNote?: string;
}

export class BroadcastEmergencyDto {
  @ApiProperty({ example: 'تحذير عاجل: طريق أربيل - دهوك مغلق مؤقتاً بسبب السيول' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'يرجى من السائقين اتخاذ طريق شيخان البديل وتوخي الحذر الشديد' })
  @IsString()
  @IsNotEmpty()
  message: string;

  @ApiPropertyOptional({ example: 'erbil-duhok-m10' })
  @IsOptional()
  @IsString()
  targetSegmentId?: string;
}
