import { IsNotEmpty, IsNumber, IsString, IsEnum, IsOptional, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum RoadQuestionType {
  TRAFFIC = 'TRAFFIC', // هل هنالك زحمة؟
  ROAD_CONDITION = 'ROAD_CONDITION', // كيف وضع الطريق؟
  ACCIDENT = 'ACCIDENT', // هل يوجد حادث؟
  CLOSURE = 'CLOSURE', // هل يوجد إغلاق؟
  CHECKPOINT = 'CHECKPOINT', // هل توجد نقطة تفتيش؟
  FUEL_AVAILABILITY = 'FUEL_AVAILABILITY', // هل توجد محطة فيها بنزين؟
  WATER_FLOOD = 'WATER_FLOOD', // هل يوجد تجمع مياه؟
  GENERAL = 'GENERAL',
}

export class AskRoadQuestionDto {
  @ApiProperty({ enum: RoadQuestionType, example: RoadQuestionType.TRAFFIC })
  @IsEnum(RoadQuestionType)
  @IsNotEmpty()
  questionType: RoadQuestionType;

  @ApiProperty({ example: 36.191113 })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 44.009167 })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ example: 315, description: 'اتجاه سير السائل بالدرجات (0-360)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(360)
  bearing?: number;

  @ApiPropertyOptional({ example: 'طريق أربيل - دهوك' })
  @IsOptional()
  @IsString()
  roadName?: string;

  @ApiPropertyOptional({ example: 'erbil-duhok-m10' })
  @IsOptional()
  @IsString()
  roadSegmentId?: string;

  @ApiPropertyOptional({ example: 'هل السيطرة مفتوحة حالياً؟' })
  @IsOptional()
  @IsString()
  customText?: string;
}

export class AnswerRoadQuestionDto {
  @ApiProperty({ example: 'YES', description: 'YES, NO, NOT_SURE, GOOD, FAIR, POOR' })
  @IsString()
  @IsNotEmpty()
  answer: string;

  @ApiPropertyOptional({ example: 36.2500 })
  @IsOptional()
  @IsNumber()
  responderLatitude?: number;

  @ApiPropertyOptional({ example: 43.8000 })
  @IsOptional()
  @IsNumber()
  responderLongitude?: number;
}
