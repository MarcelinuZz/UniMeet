import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { EventsService } from './events.service.js';
import { CreateEventDto } from './dto/create-event.dto.js';
import { FilterEventsDto } from './dto/filter-events.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Public } from '../common/decorators/public.decorator.js';

@ApiTags('Events')
@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Public()
  @Post()
  @ApiOperation({ summary: 'Host Meetup / Buat Aktivitas Kampus Baru' })
  @ApiResponse({ status: 201, description: 'Meetup berhasil dibuat' })
  async create(
    @Body() dto: CreateEventDto & { userId?: string; hostEmail?: string },
    @CurrentUser('id') authUserId?: string,
  ) {
    let userId = authUserId || dto.userId;
    if (!userId && dto.hostEmail) {
      const user = await this.eventsService['prisma'].user.findUnique({
        where: { email: dto.hostEmail.toLowerCase() },
      });
      if (user) userId = user.id;
    }
    return this.eventsService.create(userId || '', dto);
  }

  @Public()
  @Get('feed')
  @ApiOperation({ summary: 'Jelajahi Feed Aktivitas Kampus (Search, Filter Kategori & Kampus, Pagination)' })
  async findAll(@Query() dto: FilterEventsDto, @CurrentUser('id') authUserId?: string) {
    let currentUserId = authUserId || dto.userId;
    if (!currentUserId && dto.userEmail) {
      const user = await this.eventsService['prisma'].user.findUnique({
        where: { email: dto.userEmail.toLowerCase() },
      });
      if (user) currentUserId = user.id;
    }
    return this.eventsService.findAll(dto, currentUserId);
  }

  @Public()
  @Get('my-schedules')
  @ApiOperation({ summary: 'Jadwal Saya & Digital QR Turnstile Passes (Upcoming & Riwayat Selesai)' })
  async getMySchedules(
    @CurrentUser('id') authUserId?: string,
    @Query('userId') queryUserId?: string,
    @Query('email') email?: string,
  ) {
    let userId = authUserId || queryUserId;
    if (!userId && email) {
      const user = await this.eventsService['prisma'].user.findUnique({
        where: { email: email.toLowerCase() },
      });
      if (user) userId = user.id;
    }
    return this.eventsService.getMySchedules(userId || '');
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Detail Kegiatan Meetup (Info host, squad roster, & active poll)' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser('id') authUserId?: string,
    @Query('userId') queryUserId?: string,
    @Query('email') email?: string,
  ) {
    let userId = authUserId || queryUserId;
    if (!userId && email) {
      const user = await this.eventsService['prisma'].user.findUnique({
        where: { email: email.toLowerCase() },
      });
      if (user) userId = user.id;
    }
    return this.eventsService.findOne(id, userId);
  }

  @Public()
  @Post(':id/join')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'RSVP & Join Squad (Manage Roster & Automatic Waitlist)' })
  async join(
    @Param('id') eventId: string,
    @Body() body: { userId?: string; userEmail?: string },
    @CurrentUser('id') authUserId?: string,
  ) {
    let userId = authUserId || body.userId;
    if (!userId && body.userEmail) {
      const user = await this.eventsService['prisma'].user.findUnique({
        where: { email: body.userEmail.toLowerCase() },
      });
      if (user) userId = user.id;
    }
    return this.eventsService.join(eventId, userId || '');
  }

  @Public()
  @Delete(':id/leave')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Tinggalkan Squad Meetup (Otomatis mempromosikan waitlist)' })
  async leave(
    @Param('id') eventId: string,
    @Body() body: { userId?: string; userEmail?: string },
    @CurrentUser('id') authUserId?: string,
  ) {
    let userId = authUserId || body.userId;
    if (!userId && body.userEmail) {
      const user = await this.eventsService['prisma'].user.findUnique({
        where: { email: body.userEmail.toLowerCase() },
      });
      if (user) userId = user.id;
    }
    return this.eventsService.leave(eventId, userId || '');
  }
}
