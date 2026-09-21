import { IsNotEmpty, IsString, IsNumber, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateBusinessInfoDto {
  @ApiProperty({ example: 'محطة وقود كوردستان 100 متري' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: '+9647501239991' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'مفتوح 24 ساعة' })
  @IsOptional()
  @IsString()
  openingHours?: string;

  @ApiPropertyOptional({ example: 850 })
  @IsOptional()
  @IsNumber()
  petrolPrice?: number;

  @ApiPropertyOptional({ example: 1150 })
  @IsOptional()
  @IsNumber()
  premiumPrice?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({ example: 'خصم 10% على غسيل السيارات لرواد درب' })
  @IsOptional()
  @IsString()
  specialOffer?: string;
}
