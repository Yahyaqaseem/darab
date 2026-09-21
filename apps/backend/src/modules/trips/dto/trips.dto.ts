import { IsNotEmpty, IsNumber, IsString, IsArray, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTripDto {
  @ApiProperty({ example: 36.191113 })
  @IsNumber()
  startLat: number;

  @ApiProperty({ example: 44.009167 })
  @IsNumber()
  startLng: number;

  @ApiPropertyOptional({ example: 'أربيل - بارك شاندر' })
  @IsOptional()
  @IsString()
  startName?: string;

  @ApiProperty({ example: 36.8679 })
  @IsNumber()
  endLat: number;

  @ApiProperty({ example: 42.9904 })
  @IsNumber()
  endLng: number;

  @ApiPropertyOptional({ example: 'دهوك - المركز' })
  @IsOptional()
  @IsString()
  endName?: string;

  @ApiProperty({ example: 155.4, description: 'المسافة الكلية بالكيلومتر' })
  @IsNumber()
  distanceKm: number;

  @ApiProperty({ example: 8280, description: 'المدة الإجمالية بالثواني' })
  @IsNumber()
  durationSeconds: number;

  @ApiProperty({
    example: [80, 110, 115, 120, 250, 118, 122, 105],
    description: 'قراءات السرعة من الـ GPS (تتضمن طفرات عشوائية للفلترة)',
  })
  @IsArray()
  speedReadings: number[];

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsNumber()
  stopsCount?: number;

  @ApiPropertyOptional({ example: 480, description: 'التأخير بسبب الازدحام بالثواني' })
  @IsOptional()
  @IsNumber()
  trafficDelaySeconds?: number;
}
