import { Module } from '@nestjs/common';
import { SponsorshipsService } from './sponsorships.service.js';
import { SponsorshipsController } from './sponsorships.controller.js';

@Module({
  controllers: [SponsorshipsController],
  providers: [SponsorshipsService],
  exports: [SponsorshipsService],
})
export class SponsorshipsModule {}
