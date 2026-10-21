import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { AccountTier } from '@prisma/client';

@Injectable()
export class SubscriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  getPlans() {
    return [
      {
        tier: 'FREE',
        name: 'Binusian Basic',
        price: 'Rp 0 / bln',
        features: [
          'Akses feed meetup kampus',
          'Maksimal 3 meetup hosted per bulan',
          'Standar profil & Flazz digital pass',
          'Squad chat & turnstile pass',
        ],
      },
      {
        tier: 'PREMIUM',
        name: 'UniMeet Campus Pro',
        price: 'Rp 29.000 / bln',
        badge: 'Binusian Pro ⭐',
        features: [
          'Badge verifikasi Pro khusus',
          'Boost meetup listing ke puncak feed kampus',
          'Akses prioritas room booking & polling accessories',
          'Unlimited hosting aktivitas',
          'Review eksklusif portofolio kating',
        ],
      },
    ];
  }

  async upgradeToPremium(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        isPremium: true,
        tier: AccountTier.PREMIUM,
      },
      select: {
        id: true,
        name: true,
        email: true,
        isPremium: true,
        tier: true,
      },
    });

    return {
      message: 'Selamat! Akun Anda telah diupgrade ke UniMeet Campus Pro ⭐',
      user: updated,
    };
  }
}
