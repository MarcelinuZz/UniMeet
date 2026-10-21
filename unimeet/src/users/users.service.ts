import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        _count: {
          select: {
            createdEvents: true,
            participations: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    const { password, hashedRefreshToken, _count, ...userData } = user;

    return {
      ...userData,
      eventsHosted: _count.createdEvents,
      eventsJoined: _count.participations,
      gpa: user.gpa ? Number(user.gpa).toFixed(2) : '3.84',
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    let avatarInitials = user.avatarInitials;
    if (dto.name) {
      const parts = dto.name.trim().split(/\s+/);
      avatarInitials =
        parts.length === 1
          ? parts[0].substring(0, 2).toUpperCase()
          : (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.major && { major: dto.major }),
        ...(dto.batch && { batch: dto.batch }),
        ...(dto.campus && { campus: dto.campus }),
        ...(dto.bio !== undefined && { bio: dto.bio }),
        ...(dto.interests && { interests: dto.interests }),
        ...(dto.avatarUrl !== undefined && { avatarUrl: dto.avatarUrl }),
        avatarInitials,
      },
      select: {
        id: true,
        email: true,
        name: true,
        nim: true,
        major: true,
        batch: true,
        campus: true,
        bio: true,
        avatarUrl: true,
        avatarInitials: true,
        isVerified: true,
        isPremium: true,
        tier: true,
        satPoints: true,
        reputation: true,
        interests: true,
        updatedAt: true,
      },
    });

    return {
      message: 'Profil berhasil diperbarui',
      user: updated,
    };
  }

  async getUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        major: true,
        batch: true,
        campus: true,
        bio: true,
        avatarUrl: true,
        avatarInitials: true,
        isVerified: true,
        isPremium: true,
        tier: true,
        reputation: true,
        interests: true,
        _count: {
          select: {
            createdEvents: true,
            participations: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Data mahasiswa tidak ditemukan');
    }

    return user;
  }

  async getDirectory(search?: string) {
    const where: any = {};
    if (search && search.trim().length > 0) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { nim: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { major: { contains: search, mode: 'insensitive' } },
      ];
    }

    return this.prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        email: true,
        nim: true,
        major: true,
        batch: true,
        campus: true,
        bio: true,
        avatarUrl: true,
        avatarInitials: true,
        isVerified: true,
        interests: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  async getMentors(majorFilter?: string) {
    // Mentors with high reputation or specific tags
    const whereClause: any = {
      reputation: { gte: 4.8 },
    };

    if (majorFilter && majorFilter !== 'all') {
      whereClause.major = {
        contains: majorFilter,
        mode: 'insensitive',
      };
    }

    const mentors = await this.prisma.user.findMany({
      where: whereClause,
      take: 20,
      select: {
        id: true,
        name: true,
        major: true,
        batch: true,
        campus: true,
        avatarInitials: true,
        avatarUrl: true,
        reputation: true,
        bio: true,
        interests: true,
        isVerified: true,
        _count: {
          select: {
            createdEvents: true,
          },
        },
      },
      orderBy: { reputation: 'desc' },
    });

    // Fallback mock mentors if database is newly initialized
    if (mentors.length === 0) {
      return [
        {
          id: 'mentor-1',
          name: 'Oliver Wiryateja Herlianto',
          major: 'Computer Science',
          batch: "CS '24",
          campus: 'Syahdan / Anggrek',
          focus: 'Cloud & Software Engineering',
          reputation: 5.0,
          avatarInitials: 'OW',
          badge: 'Top Mentor',
          availability: 'Jumat & Sabtu sore',
        },
        {
          id: 'mentor-2',
          name: 'Melvin Goh',
          major: 'Cyber Security',
          batch: "Cyber Sec '24",
          campus: 'Anggrek',
          focus: 'Offensive Security & CTF Player',
          reputation: 4.9,
          avatarInitials: 'MG',
          badge: 'Internship Lead',
          availability: 'Malam online Discord',
        },
        {
          id: 'mentor-3',
          name: 'Samuel Joseph Wijaya',
          major: 'Interactive Design & Tech',
          batch: "IDT '25",
          campus: 'Bekasi / Anggrek',
          focus: 'UI/UX & Design Systems',
          reputation: 4.95,
          avatarInitials: 'SJ',
          badge: 'Figma Pro',
          availability: 'Sabtu siang di Library',
        },
        {
          id: 'mentor-4',
          name: 'Jecsen',
          major: 'Computer Science',
          batch: "CS '24",
          campus: 'Kijang',
          focus: 'Mobile Development & Flutter',
          reputation: 4.85,
          avatarInitials: 'JC',
          badge: 'Code Reviewer',
          availability: 'Minggu siang',
        },
      ];
    }

    return mentors;
  }

  async resolveUser(identifier: string) {
    if (!identifier) return null;
    return this.prisma.user.findFirst({
      where: {
        OR: [
          { id: identifier },
          { email: identifier.toLowerCase() },
          { nim: identifier },
        ],
      },
    });
  }

  async getFriends(identifier: string) {
    const user = await this.resolveUser(identifier);
    if (!user) return [];

    const friendships = await this.prisma.friendship.findMany({
      where: {
        status: 'ACCEPTED',
        OR: [{ senderId: user.id }, { receiverId: user.id }],
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            email: true,
            nim: true,
            major: true,
            batch: true,
            campus: true,
            avatarInitials: true,
            avatarUrl: true,
          },
        },
        receiver: {
          select: {
            id: true,
            name: true,
            email: true,
            nim: true,
            major: true,
            batch: true,
            campus: true,
            avatarInitials: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return friendships.map((f) => {
      const friend = f.senderId === user.id ? f.receiver : f.sender;
      return {
        friendshipId: f.id,
        id: friend.id,
        name: friend.name,
        email: friend.email,
        nim: friend.nim,
        major: friend.major,
        batch: friend.batch,
        campus: friend.campus,
        avatarInitials: friend.avatarInitials,
        avatarUrl: friend.avatarUrl,
        since: f.updatedAt,
      };
    });
  }

  async getFriendRequests(identifier: string) {
    const user = await this.resolveUser(identifier);
    if (!user) return [];

    const requests = await this.prisma.friendship.findMany({
      where: {
        receiverId: user.id,
        status: 'PENDING',
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            email: true,
            nim: true,
            major: true,
            batch: true,
            campus: true,
            avatarInitials: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return requests.map((r) => ({
      requestId: r.id,
      sender: r.sender,
      createdAt: r.createdAt,
    }));
  }

  async getFriendshipStatus(userIdentifier: string, targetIdentifier: string) {
    const user = await this.resolveUser(userIdentifier);
    const target = await this.resolveUser(targetIdentifier);

    if (!user || !target || user.id === target.id) {
      return { status: 'NONE' };
    }

    const friendship = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { senderId: user.id, receiverId: target.id },
          { senderId: target.id, receiverId: user.id },
        ],
      },
    });

    if (!friendship) return { status: 'NONE' };
    if (friendship.status === 'ACCEPTED') return { status: 'ACCEPTED', requestId: friendship.id };
    if (friendship.status === 'PENDING') {
      return {
        status: friendship.senderId === user.id ? 'PENDING_SENT' : 'PENDING_RECEIVED',
        requestId: friendship.id,
      };
    }
    return { status: 'NONE' };
  }

  async sendFriendRequest(senderIdentifier: string, receiverIdentifier: string) {
    const sender = await this.resolveUser(senderIdentifier);
    const receiver = await this.resolveUser(receiverIdentifier);

    if (!sender || !receiver) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    if (sender.id === receiver.id) {
      throw new BadRequestException('Tidak bisa mengirim pertemanan ke akun sendiri');
    }

    const existing = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { senderId: sender.id, receiverId: receiver.id },
          { senderId: receiver.id, receiverId: sender.id },
        ],
      },
    });

    if (existing) {
      if (existing.status === 'ACCEPTED') {
        return { success: true, message: 'Sudah berteman', status: 'ACCEPTED' };
      }
      if (existing.status === 'PENDING') {
        return { success: true, message: 'Permintaan pertemanan sedang diproses', status: 'PENDING' };
      }
      // Re-open if previously declined
      const updated = await this.prisma.friendship.update({
        where: { id: existing.id },
        data: {
          senderId: sender.id,
          receiverId: receiver.id,
          status: 'PENDING',
        },
      });
      return { success: true, message: 'Permintaan pertemanan dikirim ulang', request: updated };
    }

    const request = await this.prisma.friendship.create({
      data: {
        senderId: sender.id,
        receiverId: receiver.id,
        status: 'PENDING',
      },
    });

    return {
      success: true,
      message: `Permintaan pertemanan terkirim ke ${receiver.name}!`,
      request,
    };
  }

  async respondFriendRequest(requestId: string, action: 'ACCEPT' | 'DECLINE') {
    const request = await this.prisma.friendship.findUnique({
      where: { id: requestId },
    });

    if (!request) {
      throw new NotFoundException('Permintaan pertemanan tidak ditemukan');
    }

    if (action === 'ACCEPT') {
      const updated = await this.prisma.friendship.update({
        where: { id: requestId },
        data: { status: 'ACCEPTED' },
      });
      return { success: true, message: 'Permintaan pertemanan diterima!', friendship: updated };
    } else {
      await this.prisma.friendship.delete({
        where: { id: requestId },
      });
      return { success: true, message: 'Permintaan pertemanan ditolak' };
    }
  }

  async requestCoffeeChat(requesterId: string, mentorId: string, note?: string) {
    const requester = await this.prisma.user.findUnique({
      where: { id: requesterId },
      select: { name: true, major: true, batch: true },
    });

    // If mentorId is a real DB user, record notification
    const mentor = await this.prisma.user.findUnique({
      where: { id: mentorId },
    });

    if (mentor) {
      await this.prisma.notification.create({
        data: {
          userId: mentorId,
          title: 'Pengajuan Coffee Chat Baru ☕',
          body: `${requester?.name || 'Mahasiswa'} mengajukan sesi coffee chat kating: "${note || 'Diskusi seputar karir dan kuliah'}"`,
          type: 'EVENT_REMINDER',
          metadata: { requesterId, note },
        },
      });
    }

    return {
      success: true,
      message: 'Pengajuan coffee chat berhasil dikirim ke kating!',
      mentorId,
      requester: requester?.name,
    };
  }
}
