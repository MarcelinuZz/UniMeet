import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class SendMessageDto {
  @ApiProperty({
    example: 'Halo squad! Lapangan Badminton Court B udah resmi lunas ya.',
    description: 'Konten teks pesan',
  })
  @IsString()
  @IsNotEmpty()
  content!: string;
}
