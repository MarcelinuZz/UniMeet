import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SponsorshipsService } from './sponsorships.service.js';
import { Public } from '../common/decorators/public.decorator.js';

@ApiTags('Sponsorships')
@Controller('sponsorships')
export class SponsorshipsController {
  constructor(private readonly sponsorshipsService: SponsorshipsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Daftar promo & deals dari mitra / vendor lokal kampus' })
  @ApiQuery({ name: 'campus', required: false, description: 'Filter kampus BINUS' })
  @ApiResponse({ status: 200, description: 'Daftar penawaran vendor' })
  async getDeals(@Query('campus') campus?: string) {
    return this.sponsorshipsService.getActiveDeals(campus);
  }
}
