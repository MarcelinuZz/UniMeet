import { ApiProperty } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { ActivityCategory } from '@prisma/client';

export class CreateEventDto {
  @ApiProperty({
    example: 'Badminton Double Sparring 🏸',
    description: 'Judul aktivitas atau meetup',
  })
  @IsString()
  @IsNotEmpty()
  title!: string;

  @ApiProperty({
    example: 'Sparring ganda santai intermediate! Lapangan sudah dibooking dan lunas lewat Binus Sports Club.',
    description: 'Deskripsi lengkap meetup',
  })
  @IsString()
  @IsNotEmpty()
  description!: string;

  @ApiProperty({
    enum: ActivityCategory,
    example: ActivityCategory.SPORTS,
    description: 'Kategori aktivitas (SPORTS, ACADEMIC, GAMING, TECH, FOOD, OUTDOOR)',
  })
  @IsEnum(ActivityCategory)
  category!: ActivityCategory;

  @ApiProperty({
    example: 'Sports & Olahraga',
    required: false,
    description: 'Label tampilan kategori',
  })
  @IsString()
  @IsOptional()
  categoryLabel?: string;

  @ApiProperty({
    example: '2026-10-25T18:30:00.000Z',
    description: 'Waktu pelaksanaan format ISO-8601',
  })
  @IsNotEmpty()
  dateTime!: string;

  @ApiProperty({
    example: 'Besok, 18:30 - 20:30 WIB',
    required: false,
    description: 'String waktu untuk display praktis',
  })
  @IsString()
  @IsOptional()
  timeString?: string;

  @ApiProperty({
    example: 'Sports Hall Lt. 3 - Court B',
    description: 'Titik kumpul atau lokasi ruangan',
  })
  @IsString()
  @IsNotEmpty()
  location!: string;

  @ApiProperty({
    example: 'BINUS Anggrek Campus',
    description: 'Kampus BINUS tempat kegiatan berlangsung',
    default: 'BINUS Anggrek Campus',
  })
  @IsString()
  @IsOptional()
  campus?: string;

  @ApiProperty({
    example: 'Rp 15.000 / pax',
    default: 'Free',
    description: 'Biaya patungan atau gratis',
  })
  @IsString()
  @IsOptional()
  cost?: string;

  @ApiProperty({
    example: 6,
    default: 6,
    description: 'Kapasitas maksimal peserta squad',
  })
  @IsInt()
  @Min(2)
  maxParticipants!: number;

  @ApiProperty({
    example: 'Intermediate Sparring',
    required: false,
    description: 'Vibe atau target peserta (Casual, Competitive, Silent Room, dsb)',
  })
  @IsString()
  @IsOptional()
  vibe?: string;

  @ApiProperty({
    example: true,
    default: true,
    description: 'Hanya mahasiswa ber-email @binus.ac.id yang boleh mendaftar',
  })
  @IsBoolean()
  @IsOptional()
  campusVerifiedOnly?: boolean;
}
