import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Public } from '../common/decorators/public.decorator.js';

@ApiTags('Subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Public()
  @Get('plans')
  @ApiOperation({ summary: 'Daftar paket langganan Free & Premium UniMeet' })
  @ApiResponse({ status: 200, description: 'Rincian paket langganan' })
  getPlans() {
    return this.subscriptionsService.getPlans();
  }

  @UseGuards(JwtAuthGuard)
  @Post('upgrade')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upgrade akun mahasiswa ke UniMeet Campus Pro ⭐' })
  @ApiResponse({ status: 200, description: 'Akun berhasil diupgrade ke Pro' })
  async upgrade(@CurrentUser('id') userId: string) {
    return this.subscriptionsService.upgradeToPremium(userId);
  }
}
