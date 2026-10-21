import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
  Get,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { SsoLoginDto } from './dto/sso-login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';
import { Public } from '../common/decorators/public.decorator.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('register')
  @ApiOperation({
    summary: 'Registrasi Mahasiswa dengan Verifikasi Email Kampus (@binus.ac.id)',
  })
  @ApiResponse({ status: 201, description: 'Registrasi akun berhasil' })
  @ApiResponse({ status: 400, description: 'Email bukan domain BINUS' })
  @ApiResponse({ status: 409, description: 'Email atau NIM sudah terdaftar' })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login dengan Email BINUS & Password' })
  @ApiResponse({ status: 200, description: 'Login berhasil, mengembalikan Access & Refresh Token' })
  @ApiResponse({ status: 401, description: 'Kredensial salah' })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Public()
  @Post('sso/binusmaya')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login via Binusmaya SSO / Campus Portal' })
  @ApiResponse({ status: 200, description: 'Login SSO berhasil terverifikasi' })
  async ssoLogin(@Body() dto: SsoLoginDto) {
    return this.authService.loginWithSso(dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Perbarui Access Token menggunakan Refresh Token' })
  @ApiResponse({ status: 200, description: 'Token berhasil diperbarui' })
  @ApiResponse({ status: 401, description: 'Refresh token tidak valid' })
  async refreshTokens(@Body() dto: RefreshTokenDto) {
    // Decoding payload from refresh token to extract user ID
    // or through JWT refresh strategy
    const tokenParts = dto.refreshToken.split('.');
    if (tokenParts.length !== 3) {
      return this.authService.refreshTokens('', dto.refreshToken);
    }
    const payload = JSON.parse(Buffer.from(tokenParts[1], 'base64').toString());
    return this.authService.refreshTokens(payload.sub, dto.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Logout dan invalidate refresh token' })
  async logout(@CurrentUser('id') userId: string) {
    return this.authService.logout(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Dapatkan data profile akun yang sedang aktif' })
  async getProfile(@CurrentUser() user: any) {
    return {
      message: 'Profile aktif',
      user,
    };
  }
}
