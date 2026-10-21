import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ActivityCategory, EventStatus } from '@prisma/client';

export class FilterEventsDto {
  @ApiProperty({ required: false, description: 'Pencarian kata kunci (judul, lokasi, deskripsi)' })
  @IsString()
  @IsOptional()
  search?: string;

  @ApiProperty({
    required: false,
    enum: ActivityCategory,
    description: 'Filter kategori aktivitas',
  })
  @IsEnum(ActivityCategory)
  @IsOptional()
  category?: ActivityCategory;

  @ApiProperty({
    required: false,
    description: 'Filter kampus BINUS (Anggrek, Syahdan, Kijang, Alam Sutera, Bekasi)',
  })
  @IsString()
  @IsOptional()
  campus?: string;

  @ApiProperty({
    required: false,
    enum: EventStatus,
    description: 'Filter status event (OPEN, FULL, COMPLETED, CANCELLED)',
  })
  @IsEnum(EventStatus)
  @IsOptional()
  status?: EventStatus;

  @ApiProperty({ required: false, description: 'User email context for isJoined resolution' })
  @IsString()
  @IsOptional()
  userEmail?: string;

  @ApiProperty({ required: false, description: 'User ID context for isJoined resolution' })
  @IsString()
  @IsOptional()
  userId?: string;

  @ApiProperty({ required: false, default: 1, description: 'Halaman data (pagination)' })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  page?: number = 1;

  @ApiProperty({ required: false, default: 10, description: 'Batas data per halaman' })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  limit?: number = 10;
}
