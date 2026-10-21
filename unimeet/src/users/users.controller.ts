import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Public } from '../common/decorators/public.decorator.js';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Dapatkan profil saya (Academic info, SAT Points, Flazz card data)' })
  @ApiResponse({ status: 200, description: 'Data profil mahasiswa' })
  async getProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Put('profile')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Perbarui profil mahasiswa (Bio, major, interests/tags, avatar)' })
  @ApiResponse({ status: 200, description: 'Profil berhasil diupdate' })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(userId, dto);
  }

  @Public()
  @Get('mentors')
  @ApiOperation({ summary: 'Daftar Kating & Senior Connect untuk bimbingan & sharing' })
  @ApiQuery({ name: 'major', required: false, description: 'Filter jurusan: cs, cyber, design, all' })
  async getMentors(@Query('major') major?: string) {
    return this.usersService.getMentors(major);
  }

  @UseGuards(JwtAuthGuard)
  @Post('mentors/:mentorId/coffee-chat')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ajukan permintaan Coffee Chat dengan Kating / Senior Mentor' })
  async requestCoffeeChat(
    @CurrentUser('id') userId: string,
    @Param('mentorId') mentorId: string,
    @Body('note') note?: string,
  ) {
    return this.usersService.requestCoffeeChat(userId, mentorId, note);
  }

  @Public()
  @Get('directory')
  @ApiOperation({ summary: 'Daftar mahasiswa kampus yang terdaftar' })
  @ApiQuery({ name: 'search', required: false, description: 'Cari nama, NIM, atau jurusan' })
  async getDirectory(@Query('search') search?: string) {
    return this.usersService.getDirectory(search);
  }

  @Public()
  @Get('friends')
  @ApiOperation({ summary: 'Daftar teman yang sudah di-accept' })
  async getFriends(
    @Query('user') user?: string,
    @CurrentUser('id') authUserId?: string,
  ) {
    const identifier = user || authUserId || '';
    return this.usersService.getFriends(identifier);
  }

  @Public()
  @Get('friend-requests')
  @ApiOperation({ summary: 'Daftar permintaan pertemanan masuk' })
  async getFriendRequests(
    @Query('user') user?: string,
    @CurrentUser('id') authUserId?: string,
  ) {
    const identifier = user || authUserId || '';
    return this.usersService.getFriendRequests(identifier);
  }

  @Public()
  @Get('friendship-status')
  @ApiOperation({ summary: 'Cek status relasi pertemanan antara dua user' })
  async getFriendshipStatus(
    @Query('user') user: string,
    @Query('target') target: string,
  ) {
    return this.usersService.getFriendshipStatus(user, target);
  }

  @Public()
  @Post('friend-request')
  @ApiOperation({ summary: 'Kirim permintaan pertemanan ke mahasiswa lain' })
  async sendFriendRequest(
    @Body() body: { sender: string; receiver: string },
    @CurrentUser('id') authUserId?: string,
  ) {
    const sender = body.sender || authUserId || '';
    return this.usersService.sendFriendRequest(sender, body.receiver);
  }

  @Public()
  @Post('friend-request/respond')
  @ApiOperation({ summary: 'Terima atau tolak permintaan pertemanan' })
  async respondFriendRequest(
    @Body() body: { requestId: string; action: 'ACCEPT' | 'DECLINE' },
  ) {
    return this.usersService.respondFriendRequest(body.requestId, body.action);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Dapatkan data profil publik mahasiswa berdasarkan ID' })
  async getUserById(@Param('id') id: string) {
    return this.usersService.getUserById(id);
  }
}
