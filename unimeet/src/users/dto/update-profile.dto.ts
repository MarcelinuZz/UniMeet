import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsOptional, IsString } from 'class-validator';

export class UpdateProfileDto {
  @ApiProperty({ example: 'Marcelinus Wijaya Oey', required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ example: 'Computer Science', required: false })
  @IsString()
  @IsOptional()
  major?: string;

  @ApiProperty({ example: 'CS \'24', required: false })
  @IsString()
  @IsOptional()
  batch?: string;

  @ApiProperty({ example: 'BINUS Anggrek Campus', required: false })
  @IsString()
  @IsOptional()
  campus?: string;

  @ApiProperty({
    example: 'Software engineering enthusiast & badminton double sparring player.',
    required: false,
  })
  @IsString()
  @IsOptional()
  bio?: string;

  @ApiProperty({
    example: ['Badminton', 'Study Group', 'Gaming', 'Mobile App Jam'],
    required: false,
  })
  @IsArray()
  @IsOptional()
  interests?: string[];

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde', required: false })
  @IsString()
  @IsOptional()
  avatarUrl?: string;
}
