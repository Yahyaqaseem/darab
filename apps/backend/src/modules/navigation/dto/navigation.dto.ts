import { IsNotEmpty, IsNumber, IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CalculateRouteDto {
  @ApiProperty({ example: 36.191113, description: 'نقطة الانطلاق (خط العرض)' })
  @IsNumber()
  originLat: number;

  @ApiProperty({ example: 44.009167, description: 'نقطة الانطلاق (خط الطول)' })
  @IsNumber()
  originLng: number;

  @ApiProperty({ example: 36.8679, description: 'نقطة الوصول / دهوك (خط العرض)' })
  @IsNumber()
  destLat: number;

  @ApiProperty({ example: 42.9904, description: 'نقطة الوصول / دهوك (خط الطول)' })
  @IsNumber()
  destLng: number;

  @ApiPropertyOptional({ example: 'أربيل - بارك شاندر' })
  @IsOptional()
  @IsString()
  originName?: string;

  @ApiPropertyOptional({ example: 'دهوك - المركز' })
  @IsOptional()
  @IsString()
  destName?: string;
}
