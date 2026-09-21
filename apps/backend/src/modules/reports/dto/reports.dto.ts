import { IsNotEmpty, IsNumber, IsString, IsEnum, IsOptional, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum ReportType {
  ACCIDENT = 'ACCIDENT',
  HEAVY_TRAFFIC = 'HEAVY_TRAFFIC',
  CLOSURE = 'CLOSURE',
  DETOUR = 'DETOUR',
  CHECKPOINT = 'CHECKPOINT',
  POTHOLE = 'POTHOLE',
  HAZARD = 'HAZARD',
  WATER_ACCUMULATION = 'WATER_ACCUMULATION',
  BROKEN_CAR = 'BROKEN_CAR',
  ROAD_WORK = 'ROAD_WORK',
  OTHER = 'OTHER',
}

export enum ReportStatus {
  ACTIVE = 'ACTIVE',
  CONFIRMED = 'CONFIRMED',
  EXPIRED = 'EXPIRED',
  RESOLVED = 'RESOLVED',
  DISPUTED = 'DISPUTED',
}

export enum ConfirmationVote {
  CONFIRM = 'CONFIRM',
  NOT_THERE_ANYMORE = 'NOT_THERE_ANYMORE',
  NOT_SURE = 'NOT_SURE',
}

export class CreateReportDto {
  @ApiProperty({ enum: ReportType, example: ReportType.ACCIDENT })
  @IsEnum(ReportType)
  @IsNotEmpty()
  type: ReportType;

  @ApiProperty({ example: 36.191113 })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 44.009167 })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ example: 'طريق أربيل - دهوك السريع M10' })
  @IsOptional()
  @IsString()
  roadName?: string;

  @ApiPropertyOptional({ example: 'erbil-duhok-m10' })
  @IsOptional()
  @IsString()
  roadSegmentId?: string;

  @ApiPropertyOptional({ example: 315, description: 'Travel bearing in degrees (0-360)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(360)
  bearing?: number;

  @ApiPropertyOptional({ example: 'حادث تصادم بين سيارتين، المسار الأيمن مغلق' })
  @IsOptional()
  @IsString()
  description?: string;
}

export class ConfirmReportDto {
  @ApiProperty({ enum: ConfirmationVote, example: ConfirmationVote.CONFIRM })
  @IsEnum(ConfirmationVote)
  @IsNotEmpty()
  vote: ConfirmationVote;

  @ApiPropertyOptional({ example: 36.191113 })
  @IsOptional()
  @IsNumber()
  userLatitude?: number;

  @ApiPropertyOptional({ example: 44.009167 })
  @IsOptional()
  @IsNumber()
  userLongitude?: number;
}
