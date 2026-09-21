import { IsNotEmpty, IsNumber, IsString, IsOptional, IsBoolean, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateFuelReportDto {
  @ApiPropertyOptional({ example: 950, description: 'سعر البنزين العادي بالدينار العراقي' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  petrolPrice?: number;

  @ApiPropertyOptional({ example: 1250, description: 'سعر البنزين المحسن/السوبر بالدينار' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  premiumPrice?: number;

  @ApiPropertyOptional({ example: 750, description: 'سعر الكاز / الديزل' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  dieselPrice?: number;

  @ApiPropertyOptional({ example: true, description: 'هل البنزين متوفر حالياً؟' })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({ example: 'LOW', description: 'مستوى الازدحام: LOW, MEDIUM, HIGH' })
  @IsOptional()
  @IsString()
  crowdLevel?: string;
}
