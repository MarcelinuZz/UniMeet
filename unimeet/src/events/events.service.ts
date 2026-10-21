import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateEventDto } from './dto/create-event.dto.js';
import { FilterEventsDto } from './dto/filter-events.dto.js';
import { EventStatus, ParticipantRole, ParticipantStatus } from '@prisma/client';

@Injectable()
export class EventsService {
  constructor(private readonly prisma: PrismaService) {}

  private generateTurnstileCode(category: string, campus: string, userId: string): string {
    const catCode = category.substring(0, 5).toUpperCase();
    const campusCode = campus.toLowerCase().includes('syahdan')
      ? 'SYH'
      : campus.toLowerCase().includes('kijang')
      ? 'KIJ'
      : campus.toLowerCase().includes('alam')
      ? 'ALS'
      : campus.toLowerCase().includes('bekasi')
      ? 'BKS'
      : 'ANG';
    const rand = Math.floor(10000 + Math.random() * 90000);
    return `${catCode}-${campusCode}-${rand}`;
  }

  async create(userId: string, dto: CreateEventDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    if (dto.campusVerifiedOnly && !user.isVerified) {
      throw new ForbiddenException(
        'Hanya mahasiswa BINUS yang terverifikasi resmi yang dapat membuat kegiatan ini',
      );
    }

    const eventDate = new Date(dto.dateTime);
    if (isNaN(eventDate.getTime())) {
      throw new BadRequestException('Format tanggal dan waktu tidak valid');
    }

    const event = await this.prisma.event.create({
      data: {
        title: dto.title,
        description: dto.description,
        category: dto.category,
        categoryLabel: dto.categoryLabel || dto.category.toString(),
        dateTime: eventDate,
        timeString: dto.timeString || 'Segera Diumumkan',
        location: dto.location,
        campus: dto.campus || user.campus || 'BINUS Anggrek Campus',
        cost: dto.cost || 'Free',
        maxParticipants: dto.maxParticipants,
        vibe: dto.vibe || 'Casual',
        campusVerifiedOnly: dto.campusVerifiedOnly ?? true,
        hostId: userId,
        status: EventStatus.OPEN,
        participants: {
          create: {
            userId: userId,
            role: ParticipantRole.HOST,
            status: ParticipantStatus.JOINED,
          },
        },
      },
      include: {
        host: {
          select: {
            id: true,
            name: true,
            nim: true,
            major: true,
            campus: true,
            avatarInitials: true,
            avatarUrl: true,
            reputation: true,
          },
        },
        participants: true,
      },
    });

    return {
      message: 'Meetup berhasil dipublikasikan ke kampus!',
      event,
    };
  }

  async findAll(dto: FilterEventsDto, currentUserId?: string) {
    const page = dto.page || 1;
    const limit = dto.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (dto.category) {
      where.category = dto.category;
    }

    if (dto.campus && dto.campus !== 'all') {
      where.campus = {
        contains: dto.campus,
        mode: 'insensitive',
      };
    }

    if (dto.status) {
      where.status = dto.status;
    }

    if (dto.search) {
      where.OR = [
        { title: { contains: dto.search, mode: 'insensitive' } },
        { description: { contains: dto.search, mode: 'insensitive' } },
        { location: { contains: dto.search, mode: 'insensitive' } },
      ];
    }

    const [total, events] = await Promise.all([
      this.prisma.event.count({ where }),
      this.prisma.event.findMany({
        where,
        skip,
        take: limit,
        orderBy: { dateTime: 'asc' },
        include: {
          host: {
            select: {
              id: true,
              email: true,
              name: true,
              nim: true,
              major: true,
              batch: true,
              campus: true,
              avatarInitials: true,
              avatarUrl: true,
              reputation: true,
              isVerified: true,
              _count: {
                select: { createdEvents: true },
              },
            },
          },
          participants: {
            where: { status: ParticipantStatus.JOINED },
            include: {
              user: {
                select: {
                  id: true,
                  email: true,
                  name: true,
                  major: true,
                  batch: true,
                  avatarInitials: true,
                  avatarUrl: true,
                },
              },
            },
          },
          _count: {
            select: {
              participants: {
                where: { status: ParticipantStatus.JOINED },
              },
            },
          },
        },
      }),
    ]);

    const formattedEvents = events.map((event) => {
      const isJoined = currentUserId
        ? (event.hostId === currentUserId || event.participants.some((p) => p.userId === currentUserId))
        : false;

      return {
        id: event.id,
        title: event.title,
        description: event.description,
        category: event.category,
        categoryLabel: event.categoryLabel,
        dateTime: event.dateTime,
        timeString: event.timeString,
        location: event.location,
        campus: event.campus,
        cost: event.cost,
        maxSlots: event.maxParticipants,
        currentSlots: event._count.participants,
        status: event.status,
        vibe: event.vibe,
        campusVerifiedOnly: event.campusVerifiedOnly,
        isJoined,
        host: {
          id: event.host.id,
          email: event.host.email,
          name: event.host.name,
          nim: event.host.nim,
          major: event.host.major,
          batch: event.host.batch,
          campus: event.host.campus,
          rating: event.host.reputation,
          hostedCount: event.host._count.createdEvents,
          avatar: event.host.avatarInitials,
          avatarUrl: event.host.avatarUrl,
        },
        roster: event.participants.map((p) => ({
          userId: p.user.id,
          email: p.user.email,
          name: p.user.name,
          role: p.role,
          major: p.user.major,
          avatar: p.user.avatarInitials,
        })),
      };
    });

    return {
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
      data: formattedEvents,
    };
  }

  async findOne(id: string, currentUserId?: string) {
    const event = await this.prisma.event.findUnique({
      where: { id },
      include: {
        host: {
          select: {
            id: true,
            name: true,
            nim: true,
            major: true,
            batch: true,
            campus: true,
            avatarInitials: true,
            avatarUrl: true,
            reputation: true,
            isVerified: true,
            _count: {
              select: { createdEvents: true },
            },
          },
        },
        participants: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                major: true,
                batch: true,
                avatarInitials: true,
                avatarUrl: true,
              },
            },
          },
          orderBy: { joinedAt: 'asc' },
        },
        polls: {
          where: { isActive: true },
          include: {
            options: {
              include: {
                votes: true,
                _count: {
                  select: { votes: true },
                },
              },
            },
          },
        },
      },
    });

    if (!event) {
      throw new NotFoundException('Kegiatan meetup tidak ditemukan');
    }

    const joinedParticipants = event.participants.filter(
      (p) => p.status === ParticipantStatus.JOINED,
    );
    const isJoined = currentUserId
      ? joinedParticipants.some((p) => p.userId === currentUserId)
      : false;
    const isHost = currentUserId ? event.hostId === currentUserId : false;

    return {
      id: event.id,
      title: event.title,
      description: event.description,
      category: event.category,
      categoryLabel: event.categoryLabel,
      dateTime: event.dateTime,
      timeString: event.timeString,
      location: event.location,
      campus: event.campus,
      cost: event.cost,
      maxSlots: event.maxParticipants,
      currentSlots: joinedParticipants.length,
      status: event.status,
      vibe: event.vibe,
      campusVerifiedOnly: event.campusVerifiedOnly,
      isJoined,
      isHost,
      host: {
        id: event.host.id,
        name: event.host.name,
        nim: event.host.nim,
        major: event.host.major,
        campus: event.host.campus,
        rating: event.host.reputation,
        hostedCount: event.host._count.createdEvents,
        avatar: event.host.avatarInitials,
        avatarUrl: event.host.avatarUrl,
      },
      roster: event.participants.map((p) => ({
        id: p.id,
        userId: p.user.id,
        name: p.user.name,
        role: p.role,
        status: p.status,
        major: p.user.major,
        avatar: p.user.avatarInitials,
        isCurrentUser: currentUserId === p.user.id,
      })),
      polls: event.polls.map((poll) => {
        const totalVotes = poll.options.reduce((sum, opt) => sum + opt._count.votes, 0);
        return {
          id: poll.id,
          question: poll.question,
          totalVotes,
          options: poll.options.map((opt) => ({
            id: opt.id,
            text: opt.text,
            voteCount: opt._count.votes,
            percentage: totalVotes > 0 ? Math.round((opt._count.votes / totalVotes) * 100) : 0,
            hasVoted: currentUserId
              ? opt.votes.some((v) => v.userId === currentUserId)
              : false,
          })),
        };
      }),
    };
  }

  async join(eventId: string, userId: string) {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        participants: {
          where: { status: ParticipantStatus.JOINED },
        },
      },
    });

    if (!event) {
      throw new NotFoundException('Event tidak ditemukan');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    if (event.campusVerifiedOnly && !user.isVerified) {
      throw new ForbiddenException(
        'Aktivitas ini khusus untuk mahasiswa BINUS yang terverifikasi',
      );
    }

    // Check if user is already participating
    const existing = await this.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: {
          eventId,
          userId,
        },
      },
    });

    if (existing && existing.status === ParticipantStatus.JOINED) {
      throw new ConflictException('Anda sudah bergabung dalam squad kegiatan ini');
    }

    const currentCount = event.participants.length;
    let participantRole: ParticipantRole = ParticipantRole.MEMBER;
    let participantStatus: ParticipantStatus = ParticipantStatus.JOINED;

    if (currentCount >= event.maxParticipants) {
      // Put on waitlist
      participantRole = ParticipantRole.WAITLIST;
      participantStatus = ParticipantStatus.WAITLISTED;
    }

    let participation;
    if (existing) {
      participation = await this.prisma.eventParticipant.update({
        where: { id: existing.id },
        data: {
          role: participantRole,
          status: participantStatus,
          joinedAt: new Date(),
        },
      });
    } else {
      participation = await this.prisma.eventParticipant.create({
        data: {
          eventId,
          userId,
          role: participantRole,
          status: participantStatus,
        },
      });
    }

    // If reached max capacity, update event status to FULL
    if (participantStatus === ParticipantStatus.JOINED && currentCount + 1 >= event.maxParticipants) {
      await this.prisma.event.update({
        where: { id: eventId },
        data: { status: EventStatus.FULL },
      });
    }

    // Notify host
    if (event.hostId !== userId) {
      await this.prisma.notification.create({
        data: {
          userId: event.hostId,
          title: 'Squad Member Baru! 👥',
          body: `${user.name} bergabung ke squad "${event.title}" (${participantStatus === ParticipantStatus.WAITLISTED ? 'Waitlist' : 'Confirmed'})`,
          type: 'EVENT_JOIN',
          metadata: { eventId, userId },
        },
      });
    }

    // Send system message in squad chat
    await this.prisma.message.create({
      data: {
        eventId,
        senderId: userId,
        isSystem: true,
        content: `👋 ${user.name} bergabung ke squad meetup!`,
      },
    });

    const ticketCode = this.generateTurnstileCode(event.category, event.campus, userId);

    return {
      message:
        participantStatus === ParticipantStatus.JOINED
          ? 'Berhasil bergabung dengan squad meetup!'
          : 'Kapasitas penuh. Anda dimasukkan ke dalam daftar tunggu (Waitlist).',
      status: participantStatus,
      ticketCode,
      participation,
    };
  }

  async leave(eventId: string, userId: string) {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new NotFoundException('Event tidak ditemukan');
    }

    if (event.hostId === userId) {
      throw new BadRequestException(
        'Host tidak dapat meninggalkan event. Anda dapat membatalkan / mengedit event.',
      );
    }

    const participant = await this.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: {
          eventId,
          userId,
        },
      },
    });

    if (!participant || participant.status === ParticipantStatus.CANCELLED) {
      throw new NotFoundException('Anda belum terdaftar dalam kegiatan ini');
    }

    await this.prisma.eventParticipant.delete({
      where: { id: participant.id },
    });

    // Check if there are waitlisted members to promote
    const waitlisted = await this.prisma.eventParticipant.findFirst({
      where: {
        eventId,
        status: ParticipantStatus.WAITLISTED,
      },
      orderBy: { joinedAt: 'asc' },
    });

    if (waitlisted) {
      await this.prisma.eventParticipant.update({
        where: { id: waitlisted.id },
        data: {
          role: ParticipantRole.MEMBER,
          status: ParticipantStatus.JOINED,
        },
      });

      // Notify promoted user
      await this.prisma.notification.create({
        data: {
          userId: waitlisted.userId,
          title: 'Slot Squad Terbuka! 🎟️',
          body: `Slot tersedia! Anda dipromosikan dari waitlist ke peserta aktif di "${event.title}"`,
          type: 'EVENT_JOIN',
          metadata: { eventId },
        },
      });
    } else {
      // Event status can go back to OPEN if it was FULL
      await this.prisma.event.update({
        where: { id: eventId },
        data: { status: EventStatus.OPEN },
      });
    }

    return {
      message: 'Anda berhasil keluar dari squad meetup.',
    };
  }

  async getMySchedules(userId: string) {
    const participations = await this.prisma.eventParticipant.findMany({
      where: {
        userId,
        status: ParticipantStatus.JOINED,
      },
      include: {
        event: {
          include: {
            host: {
              select: {
                id: true,
                name: true,
                major: true,
                avatarInitials: true,
              },
            },
          },
        },
      },
      orderBy: {
        event: {
          dateTime: 'asc',
        },
      },
    });

    const now = new Date();
    const upcoming: any[] = [];
    const past: any[] = [];

    for (const p of participations) {
      const ev = p.event;
      const isUpcoming = new Date(ev.dateTime) >= now;
      const ticketCode = this.generateTurnstileCode(ev.category, ev.campus, userId);

      const scheduleItem = {
        id: ev.id,
        title: ev.title,
        category: ev.category,
        dateTime: ev.dateTime,
        timeString: ev.timeString,
        location: ev.location,
        campus: ev.campus,
        cost: ev.cost,
        role: p.role,
        status: 'CONFIRMED',
        ticketCode,
        turnstilePass: {
          ticket: ticketCode,
          venue: ev.location,
          campus: ev.campus,
          gate: 'Sports Hall Lt. 3 Turnstile / Library Turnstile Gate',
        },
        host: ev.host,
      };

      if (isUpcoming) {
        upcoming.push(scheduleItem);
      } else {
        past.push(scheduleItem);
      }
    }

    return {
      upcomingCount: upcoming.length,
      pastCount: past.length,
      upcoming,
      past,
    };
  }
}
