import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { SsoLoginDto } from './dto/sso-login.dto.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  private extractInitials(name: string): string {
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  private validateBinusEmail(email: string): boolean {
    const binusRegex = /^[a-zA-Z0-9._%+-]+@(binus\.ac\.id|binus\.edu|alumni\.binus\.ac\.id)$/i;
    return binusRegex.test(email);
  }

  async register(dto: RegisterDto) {
    if (!this.validateBinusEmail(dto.email)) {
      throw new BadRequestException(
        'Hanya email resmi BINUS (@binus.ac.id, @binus.edu, @alumni.binus.ac.id) yang diizinkan mendaftar.',
      );
    }

    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: dto.email.toLowerCase() }, { nim: dto.nim }],
      },
    });

    if (existingUser) {
      if (existingUser.email === dto.email.toLowerCase()) {
        throw new ConflictException('Email BINUS sudah terdaftar.');
      }
      throw new ConflictException('NIM Binusian sudah terdaftar.');
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(dto.password, saltRounds);
    const initials = this.extractInitials(dto.name);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        password: hashedPassword,
        name: dto.name,
        nim: dto.nim,
        major: dto.major || 'Computer Science',
        batch: dto.batch || '2024',
        campus: dto.campus || 'BINUS Anggrek Campus',
        avatarInitials: initials,
        isVerified: true,
        interests: dto.interests || ['Badminton', 'Study Group', 'Gaming'],
        satPoints: 100,
        gpa: 3.75,
        reputation: 5.0,
      },
      select: {
        id: true,
        email: true,
        name: true,
        nim: true,
        major: true,
        batch: true,
        campus: true,
        avatarInitials: true,
        isVerified: true,
        isPremium: true,
        tier: true,
        satPoints: true,
        reputation: true,
        interests: true,
      },
    });

    const tokens = await this.generateTokens(user.id, user.email, user.nim || undefined, user.campus || undefined);
    await this.updateRefreshToken(user.id, tokens.refreshToken);

    return {
      message: 'Registrasi berhasil dan email kampus terverifikasi',
      user,
      tokens,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (!user) {
      throw new UnauthorizedException('Kredensial tidak valid (Email tidak terdaftar)');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Kredensial tidak valid (Kata sandi salah)');
    }

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.nim || undefined,
      user.campus || undefined,
    );
    await this.updateRefreshToken(user.id, tokens.refreshToken);

    const { password, hashedRefreshToken, ...safeUser } = user;

    return {
      message: 'Login berhasil',
      user: safeUser,
      tokens,
    };
  }

  async loginWithSso(dto: SsoLoginDto) {
    // Mock / Simulate BINUS SSO Verification with Binusmaya Portal
    this.logger.log(`Memproses verifikasi SSO untuk ticket: ${dto.ssoTicket}`);

    if (!dto.ssoTicket) {
      throw new BadRequestException('Tiket SSO Binusmaya tidak valid');
    }

    const studentEmail = (dto.email || 'marcelinus.wijaya@binus.ac.id').toLowerCase();
    const studentNim = dto.nim || '2602194831';

    let user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: studentEmail }, { nim: studentNim }],
      },
    });

    if (!user) {
      // Auto provision from Binusmaya SSO
      const randomPass = await bcrypt.hash(`SSO_BINUS_${Date.now()}`, 10);
      user = await this.prisma.user.create({
        data: {
          email: studentEmail,
          password: randomPass,
          name: 'Marcelinus Wijaya Oey',
          nim: studentNim,
          major: 'Computer Science',
          batch: '2024',
          campus: 'BINUS Anggrek Campus',
          avatarInitials: 'MW',
          isVerified: true,
          satPoints: 118,
          gpa: 3.84,
          reputation: 4.95,
          interests: ['Badminton', 'Study Group', 'Gaming', 'Mobile Jam'],
        },
      });
    }

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.nim || undefined,
      user.campus || undefined,
    );
    await this.updateRefreshToken(user.id, tokens.refreshToken);

    const { password, hashedRefreshToken, ...safeUser } = user;

    return {
      message: 'Login SSO Binusmaya Berhasil',
      ssoStatus: 'VERIFIED_STUDENT',
      user: safeUser,
      tokens,
    };
  }

  async refreshTokens(userId: string, refreshToken: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || !user.hashedRefreshToken) {
      throw new UnauthorizedException('Akses ditolak (Sesi tidak ditemukan)');
    }

    const isMatch = await bcrypt.compare(refreshToken, user.hashedRefreshToken);
    if (!isMatch) {
      throw new UnauthorizedException('Refresh token tidak valid atau telah kedaluwarsa');
    }

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.nim || undefined,
      user.campus || undefined,
    );
    await this.updateRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  async logout(userId: string) {
    await this.prisma.user.updateMany({
      where: {
        id: userId,
        hashedRefreshToken: { not: null },
      },
      data: {
        hashedRefreshToken: null,
      },
    });
    return { message: 'Berhasil keluar dari akun (Logout)' };
  }

  private async updateRefreshToken(userId: string, refreshToken: string) {
    const hashed = await bcrypt.hash(refreshToken, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { hashedRefreshToken: hashed },
    });
  }

  private async generateTokens(userId: string, email: string, nim?: string, campus?: string) {
    const payload = { sub: userId, email, nim, campus };
    const jwtSecret = this.configService.get<string>('JWT_SECRET') || 'unimeet-binus-jwt-secret-key-2025';
    const refreshSecret =
      this.configService.get<string>('JWT_REFRESH_SECRET') ||
      'unimeet-binus-refresh-secret-key-2025';

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: jwtSecret,
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: refreshSecret,
        expiresIn: '7d',
      }),
    ]);

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: 900, // 15 mins
    };
  }
}
