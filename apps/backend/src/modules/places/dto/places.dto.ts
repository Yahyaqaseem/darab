import { IsNotEmpty, IsNumber, IsString, IsOptional, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePlaceReviewDto {
  @ApiProperty({ example: 5, minimum: 1, maximum: 5 })
  @IsNumber()
  @Min(1)
  @Max(5)
  @IsNotEmpty()
  rating: number;

  @ApiPropertyOptional({ example: 'خدمة سريعة وممتازة وأسعار مناسبة جداً' })
  @IsOptional()
  @IsString()
  comment?: string;
}

export class CreatePlaceDto {
  @ApiProperty({ example: 'tire_repair' })
  @IsString()
  @IsNotEmpty()
  categoryKey: string;

  @ApiProperty({ example: 'بنجرجي دهوك السريع' })
  @IsString()
  @IsNotEmpty()
  nameAr: string;

  @ApiPropertyOptional({ example: 'Duhok Fast Tire Repair' })
  @IsOptional()
  @IsString()
  nameEn?: string;

  @ApiPropertyOptional({ example: 'پەنجەرچی خێرای دهۆک' })
  @IsOptional()
  @IsString()
  nameKu?: string;

  @ApiProperty({ example: 36.8600 })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 42.9800 })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ example: 'دهوك - مدخل المدينة قرب السيطرة' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: '+9647504445566' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: '24/7' })
  @IsOptional()
  @IsString()
  openingHours?: string;
}
