import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class VotePollDto {
  @ApiProperty({
    example: 'poll-option-uuid-1',
    description: 'ID opsi polling yang dipilih',
  })
  @IsString()
  @IsNotEmpty()
  optionId!: string;
}
