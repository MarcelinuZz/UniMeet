import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  Matches,
  IsOptional,
  IsArray,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({
    example: 'marcelinus.wijaya@binus.ac.id',
    description: 'BINUS institutional email (@binus.ac.id, @binus.edu, or @alumni.binus.ac.id)',
  })
  @IsEmail({}, { message: 'Format email tidak valid' })
  @Matches(/^[a-zA-Z0-9._%+-]+@(binus\.ac\.id|binus\.edu|alumni\.binus\.ac\.id)$/i, {
    message: 'UniMeet hanya menerima email institusi BINUS (@binus.ac.id, @binus.edu, @alumni.binus.ac.id)',
  })
  email!: string;

  @ApiProperty({ example: 'SecretP@ss123!', description: 'Password minimal 6 karakter' })
  @IsString()
  @MinLength(6, { message: 'Password minimal terdiri dari 6 karakter' })
  password!: string;

  @ApiProperty({ example: 'Marcelinus Wijaya Oey', description: 'Nama lengkap mahasiswa' })
  @IsString()
  @IsNotEmpty({ message: 'Nama tidak boleh kosong' })
  name!: string;

  @ApiProperty({ example: '2602194831', description: 'NIM Binusian' })
  @IsString()
  @IsNotEmpty({ message: 'NIM wajib diisi' })
  nim!: string;

  @ApiProperty({ example: 'Computer Science', description: 'Program studi / jurusan' })
  @IsString()
  @IsOptional()
  major?: string;

  @ApiProperty({ example: '2024', description: 'Angkatan / cohort year' })
  @IsString()
  @IsOptional()
  batch?: string;

  @ApiProperty({ example: 'BINUS Anggrek Campus', description: 'Kampus utama BINUS' })
  @IsString()
  @IsOptional()
  campus?: string;

  @ApiProperty({ example: ['Badminton', 'Study Group', 'Gaming'], description: 'Tag minat aktivitas' })
  @IsArray()
  @IsOptional()
  interests?: string[];
}
