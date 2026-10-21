import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ChatService } from './chat.service.js';
import { SendMessageDto } from './dto/send-message.dto.js';
import { CreatePollDto } from './dto/create-poll.dto.js';
import { VotePollDto } from './dto/vote-poll.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

import { Public } from '../common/decorators/public.decorator.js';

@ApiTags('Chat')
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Public()
  @Get('direct/messages')
  @ApiOperation({ summary: 'Dapatkan riwayat direct chat 1-on-1 antar teman' })
  async getDirectMessages(
    @Query('user') user?: string,
    @Query('partner') partner?: string,
    @CurrentUser('id') authUserId?: string,
  ) {
    const userIdentifier = user || authUserId || '';
    return this.chatService.getDirectMessages(userIdentifier, partner || '');
  }

  @Public()
  @Post('direct/messages')
  @ApiOperation({ summary: 'Kirim pesan direct chat 1-on-1 ke teman' })
  async sendDirectMessage(
    @Body()
    body: {
      sender?: string;
      senderEmail?: string;
      receiver?: string;
      receiverEmail?: string;
      content: string;
    },
    @CurrentUser('id') authUserId?: string,
  ) {
    const sender = body.senderEmail || body.sender || authUserId || '';
    const receiver = body.receiverEmail || body.receiver || '';
    return this.chatService.sendDirectMessage(sender, receiver, body.content);
  }

  @Public()
  @Get(':eventId/messages')
  @ApiOperation({ summary: 'Dapatkan riwayat chat room squad meetup' })
  @ApiResponse({ status: 200, description: 'Riwayat pesan squad' })
  async getMessages(@Param('eventId') eventId: string) {
    return this.chatService.getMessages(eventId);
  }

  @Public()
  @Post(':eventId/messages')
  @ApiOperation({ summary: 'Kirim pesan teks ke chat room squad' })
  @ApiResponse({ status: 201, description: 'Pesan terkirim' })
  async sendMessage(
    @Param('eventId') eventId: string,
    @Body() dto: SendMessageDto & { userId?: string; senderEmail?: string; email?: string; sender?: string },
    @CurrentUser('id') authUserId?: string,
  ) {
    const identifier = authUserId || dto.senderEmail || dto.email || dto.sender || dto.userId || '';
    const user = await this.chatService.resolveUser(identifier);
    const userId = user ? user.id : (authUserId || dto.userId || 'anonymous');
    return this.chatService.sendMessage(eventId, userId, dto.content);
  }

  @Post(':eventId/polls')
  @ApiOperation({ summary: 'Buat polling interaktif dalam squad (e.g. waktu pemanasan, lokasi)' })
  @ApiResponse({ status: 201, description: 'Polling squad dibuat' })
  async createPoll(
    @Param('eventId') eventId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreatePollDto,
  ) {
    return this.chatService.createPoll(eventId, userId, dto);
  }

  @Post('polls/:pollId/vote')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Berikan voting pada polling squad' })
  @ApiResponse({ status: 200, description: 'Voting berhasil direkam' })
  async votePoll(
    @Param('pollId') pollId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: VotePollDto,
  ) {
    return this.chatService.votePoll(pollId, dto.optionId, userId);
  }

  @Post(':eventId/icebreaker')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Trigger otomatis pertanyaan Icebreaker kampus dari bot UniMeet' })
  async triggerIcebreaker(
    @Param('eventId') eventId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.chatService.triggerIcebreaker(eventId, userId);
  }
}
