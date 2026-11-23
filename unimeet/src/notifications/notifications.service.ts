import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async getUserNotifications(userIdentifier: string) {
    if (!userIdentifier) {
      return { unreadCount: 0, notifications: [] };
    }

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { id: userIdentifier },
          { email: userIdentifier },
        ],
      },
    });

    if (!user) {
      return { unreadCount: 0, notifications: [] };
    }

    const notifications = await this.prisma.notification.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
      take: 30,
    });

    const unreadCount = await this.prisma.notification.count({
      where: { userId: user.id, isRead: false },
    });

    return {
      unreadCount,
      notifications,
    };
  }

  async markAsRead(userIdentifier: string, notificationId?: string) {
    if (!userIdentifier) {
      return { success: false, message: 'User identifier required' };
    }

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { id: userIdentifier },
          { email: userIdentifier },
        ],
      },
    });

    if (!user) {
      return { success: false, message: 'User not found' };
    }

    if (notificationId) {
      await this.prisma.notification.updateMany({
        where: { id: notificationId, userId: user.id },
        data: { isRead: true },
      });
    } else {
      await this.prisma.notification.updateMany({
        where: { userId: user.id, isRead: false },
        data: { isRead: true },
      });
    }

    return { success: true, message: 'Notifikasi ditandai telah dibaca' };
  }
}
