import { ApiProperty } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsNotEmpty, IsString } from 'class-validator';

export class CreatePollDto {
  @ApiProperty({
    example: 'Pemanasan & stretching bareng mulai jam berapa guys?',
    description: 'Pertanyaan polling untuk squad',
  })
  @IsString()
  @IsNotEmpty()
  question!: string;

  @ApiProperty({
    example: ['18:15 WIB (15 menit sebelum)', '18:30 WIB (On time langsung main)'],
    description: 'Pilihan opsi polling (minimal 2)',
  })
  @IsArray()
  @ArrayMinSize(2)
  @IsString({ each: true })
  options!: string[];
}
