import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  @ApiProperty({
    example: 'marcelinus.wijaya@binus.ac.id',
    description: 'Email institusi Binusian',
  })
  @IsEmail({}, { message: 'Format email tidak valid' })
  @IsNotEmpty()
  email!: string;

  @ApiProperty({
    example: 'SecretP@ss123!',
    description: 'Kata sandi akun',
  })
  @IsString()
  @IsNotEmpty()
  password!: string;
}
