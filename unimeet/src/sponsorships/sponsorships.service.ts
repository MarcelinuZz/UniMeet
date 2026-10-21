import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class SponsorshipsService {
  constructor(private readonly prisma: PrismaService) {}

  async getActiveDeals(campus?: string) {
    const where: any = { isActive: true };
    if (campus && campus !== 'all') {
      where.campus = {
        contains: campus,
        mode: 'insensitive',
      };
    }

    const deals = await this.prisma.sponsorship.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    if (deals.length === 0) {
      return [
        {
          id: 'deal-1',
          vendorName: 'Syahdan Boba Alley',
          title: 'Diskon 15% Squad Gaming Binus',
          description: 'Khusus squad meetup Valorant & Mobile Jam yang datang ber-4 atau lebih.',
          dealPromo: 'CODE: BOBASQUAD15',
          campus: 'BINUS Syahdan Campus',
          category: 'Food & Beverage',
        },
        {
          id: 'deal-2',
          vendorName: 'Champion Badminton Arena',
          title: 'Free 1 Shuttlecock Tube untuk Sparring',
          description: 'Booking lapangan 2 jam via UniMeet dapat gratis 1 tube shuttlecock Yonex.',
          dealPromo: 'PARTNER: BSC-CHAMPION',
          campus: 'BINUS Anggrek Campus',
          category: 'Sports & Venue',
        },
        {
          id: 'deal-3',
          vendorName: 'Kopi Kenangan Kampus Kijang',
          title: 'Buy 1 Get 1 Coffee Chat Kating',
          description: 'Tunjukkan tiket UniMeet Coffee Chat di kasir untuk klaim promo.',
          dealPromo: 'PROMO: KATINGCHAT',
          campus: 'BINUS Kijang Campus',
          category: 'Cafe & Coworking',
        },
      ];
    }

    return deals;
  }
}
