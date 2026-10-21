import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SsoLoginDto {
  @ApiProperty({
    example: 'binus_sso_ticket_94831abc',
    description: 'Ticket atau token autentikasi Binusmaya SSO',
  })
  @IsString()
  @IsNotEmpty()
  ssoTicket!: string;

  @ApiProperty({
    example: '2602194831',
    description: 'NIM Binusian untuk verifikasi SSO',
    required: false,
  })
  @IsString()
  @IsOptional()
  nim?: string;

  @ApiProperty({
    example: 'marcelinus.wijaya@binus.ac.id',
    description: 'Email Binusian',
    required: false,
  })
  @IsString()
  @IsOptional()
  email?: string;
}
