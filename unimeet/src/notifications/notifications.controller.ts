import { Controller, Get, Patch, Param, UseGuards, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Public } from '../common/decorators/public.decorator.js';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Daftar notifikasi aktivitas dan alert join squad' })
  @ApiResponse({ status: 200, description: 'Daftar notifikasi & jumlah unread' })
  async getNotifications(
    @Query('user') user?: string,
    @CurrentUser('id') authUserId?: string,
  ) {
    const identifier = user || authUserId || '';
    return this.notificationsService.getUserNotifications(identifier);
  }

  @Public()
  @Patch('read-all')
  @ApiOperation({ summary: 'Tandai semua notifikasi sudah dibaca' })
  async markAllAsRead(
    @Query('user') user?: string,
    @CurrentUser('id') authUserId?: string,
  ) {
    const identifier = user || authUserId || '';
    return this.notificationsService.markAsRead(identifier);
  }

  @Public()
  @Patch(':id/read')
  @ApiOperation({ summary: 'Tandai satu notifikasi tertentu sudah dibaca' })
  async markAsRead(
    @Param('id') id: string,
    @Query('user') user?: string,
    @CurrentUser('id') authUserId?: string,
  ) {
    const identifier = user || authUserId || '';
    return this.notificationsService.markAsRead(identifier, id);
  }
}
