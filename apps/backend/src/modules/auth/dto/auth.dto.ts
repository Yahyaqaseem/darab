import { IsNotEmpty, IsPhoneNumber, IsString, Length, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RequestOtpDto {
  @ApiProperty({ example: '+9647501234567', description: 'Iraqi phone number' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '+9647501234567' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @ApiProperty({ example: '123456', description: '6-digit OTP code' })
  @IsString()
  @Length(4, 6)
  otp: string;

  @ApiPropertyOptional({ example: 'سائق_درب', description: 'Driver handle/username' })
  @IsOptional()
  @IsString()
  username?: string;
}

export class AuthResponseDto {
  @ApiProperty()
  accessToken: string;

  @ApiProperty()
  user: {
    id: string;
    phoneNumber: string;
    username: string;
    trustLevel: string;
    reputationScore: number;
  };
}
