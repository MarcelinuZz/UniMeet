import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreatePollDto } from './dto/create-poll.dto.js';
import { ParticipantStatus } from '@prisma/client';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly icebreakers = [
    'Siapa yang berangkat dari kosan dekat Syahdan / Kijang? Mau tebeng bareng?',
    'Ada yang mau pesen cemilan atau minum boba bareng sebelum meetup?',
    'Kalian ambil mata kuliah apa semester ini yang paling seru/challenging?',
    'Share Spotify playlist yang enak buat warming up atau belajar dong!',
    'Ada yang bawa raket / shuttlecock / card game tambahan buat cadangan?',
  ];

  async verifyParticipant(eventId: string, userId: string) {
    if (!userId || userId === 'anonymous') return null;
    const user = await this.resolveUser(userId);
    const resolvedUserId = user ? user.id : userId;

    const participant = await this.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: {
          eventId,
          userId: resolvedUserId,
        },
      },
    });

    if (!participant || participant.status !== ParticipantStatus.JOINED) {
      const event = await this.prisma.event.findUnique({ where: { id: eventId } });
      if (event && event.hostId === resolvedUserId) return null;
      try {
        return await this.prisma.eventParticipant.upsert({
          where: { eventId_userId: { eventId, userId: resolvedUserId } },
          create: { eventId, userId: resolvedUserId, status: ParticipantStatus.JOINED },
          update: { status: ParticipantStatus.JOINED },
        });
      } catch (_) {
        return null;
      }
    }

    return participant;
  }

  async getMessages(eventId: string, limit = 50) {
    const messages = await this.prisma.message.findMany({
      where: { eventId },
      take: limit,
      orderBy: { createdAt: 'asc' },
      include: {
        sender: {
          select: {
            id: true,
            email: true,
            name: true,
            major: true,
            avatarInitials: true,
            avatarUrl: true,
          },
        },
        event: {
          select: {
            hostId: true,
          },
        },
      },
    });

    return messages.map((m) => ({
      id: m.id,
      eventId: m.eventId,
      senderId: m.senderId,
      senderEmail: m.sender.email,
      senderName: m.sender.name,
      senderMajor: m.sender.major,
      senderAvatar: m.sender.avatarInitials,
      isHost: m.senderId === m.event.hostId,
      isSystem: m.isSystem,
      content: m.content,
      createdAt: m.createdAt,
    }));
  }

  async sendMessage(eventId: string, senderIdentifier: string, content: string, isSystem = false) {
    const user = await this.resolveUser(senderIdentifier);
    const senderId = user ? user.id : senderIdentifier;

    if (!isSystem) {
      await this.verifyParticipant(eventId, senderId);
    }

    const message = await this.prisma.message.create({
      data: {
        eventId,
        senderId,
        content,
        isSystem,
      },
      include: {
        sender: {
          select: {
            id: true,
            email: true,
            name: true,
            major: true,
            avatarInitials: true,
            avatarUrl: true,
          },
        },
        event: {
          select: {
            hostId: true,
          },
        },
      },
    });

    return {
      id: message.id,
      eventId: message.eventId,
      senderId: message.senderId,
      senderEmail: message.sender.email,
      senderName: message.sender.name,
      senderMajor: message.sender.major,
      senderAvatar: message.sender.avatarInitials,
      isHost: message.senderId === message.event.hostId,
      isSystem: message.isSystem,
      content: message.content,
      createdAt: message.createdAt,
    };
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

  async getDirectMessages(userIdentifier: string, partnerIdentifier: string) {
    const user = await this.resolveUser(userIdentifier);
    const partner = await this.resolveUser(partnerIdentifier);

    if (!user || !partner) {
      return {
        canChat: false,
        status: 'USER_NOT_FOUND',
        reason: 'Pengguna tidak ditemukan',
        messages: [],
      };
    }

    // Check friendship: must be ACCEPTED
    const friendship = await this.prisma.friendship.findFirst({
      where: {
        status: 'ACCEPTED',
        OR: [
          { senderId: user.id, receiverId: partner.id },
          { senderId: partner.id, receiverId: user.id },
        ],
      },
    });

    if (!friendship) {
      // Check if pending
      const pending = await this.prisma.friendship.findFirst({
        where: {
          status: 'PENDING',
          OR: [
            { senderId: user.id, receiverId: partner.id },
            { senderId: partner.id, receiverId: user.id },
          ],
        },
      });

      return {
        canChat: false,
        status: pending ? (pending.senderId === user.id ? 'PENDING_SENT' : 'PENDING_RECEIVED') : 'NOT_FRIENDS',
        reason: 'Hanya dapat chat setelah permintaan pertemanan diterima.',
        messages: [],
      };
    }

    const messages = await this.prisma.directMessage.findMany({
      where: {
        OR: [
          { senderId: user.id, receiverId: partner.id },
          { senderId: partner.id, receiverId: user.id },
        ],
      },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarInitials: true,
          },
        },
      },
    });

    return {
      canChat: true,
      status: 'ACCEPTED',
      partner: {
        id: partner.id,
        name: partner.name,
        email: partner.email,
        avatarInitials: partner.avatarInitials,
      },
      messages: messages.map((m) => ({
        id: m.id,
        senderId: m.senderId,
        senderName: m.sender.name,
        senderEmail: m.sender.email,
        senderAvatar: m.sender.avatarInitials,
        content: m.content,
        createdAt: m.createdAt,
        isMe: m.senderId === user.id,
      })),
    };
  }

  async sendDirectMessage(senderIdentifier: string, receiverIdentifier: string, content: string) {
    const sender = await this.resolveUser(senderIdentifier);
    const receiver = await this.resolveUser(receiverIdentifier);

    if (!sender || !receiver) {
      throw new NotFoundException('Pengguna tidak ditemukan');
    }

    // Verify friendship is ACCEPTED
    const friendship = await this.prisma.friendship.findFirst({
      where: {
        status: 'ACCEPTED',
        OR: [
          { senderId: sender.id, receiverId: receiver.id },
          { senderId: receiver.id, receiverId: sender.id },
        ],
      },
    });

    if (!friendship) {
      throw new ForbiddenException('Hanya dapat mengirim pesan setelah berteman (permintaan pertemanan diterima).');
    }

    const msg = await this.prisma.directMessage.create({
      data: {
        senderId: sender.id,
        receiverId: receiver.id,
        content,
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarInitials: true,
          },
        },
      },
    });

    return {
      id: msg.id,
      senderId: msg.senderId,
      senderName: msg.sender.name,
      senderEmail: msg.sender.email,
      senderAvatar: msg.sender.avatarInitials,
      content: msg.content,
      createdAt: msg.createdAt,
    };
  }

  async createPoll(eventId: string, userId: string, dto: CreatePollDto) {
    await this.verifyParticipant(eventId, userId);

    const poll = await this.prisma.poll.create({
      data: {
        eventId,
        question: dto.question,
        options: {
          create: dto.options.map((opt) => ({ text: opt })),
        },
      },
      include: {
        options: {
          include: {
            _count: {
              select: { votes: true },
            },
          },
        },
      },
    });

    // Notify squad via system message
    await this.sendMessage(
      eventId,
      userId,
      `🗳️ Polling baru dibuka: "${dto.question}". Silakan berikan voting squad kalian!`,
      true,
    );

    return poll;
  }

  async votePoll(pollId: string, optionId: string, userId: string) {
    const poll = await this.prisma.poll.findUnique({
      where: { id: pollId },
      include: {
        options: true,
      },
    });

    if (!poll) {
      throw new NotFoundException('Polling tidak ditemukan');
    }

    await this.verifyParticipant(poll.eventId, userId);

    const validOption = poll.options.find((opt) => opt.id === optionId);
    if (!validOption) {
      throw new BadRequestException('Opsi polling tidak valid');
    }

    // Remove any previous vote by this user on this poll
    const optionIds = poll.options.map((o) => o.id);
    await this.prisma.pollVote.deleteMany({
      where: {
        pollOptionId: { in: optionIds },
        userId,
      },
    });

    // Cast new vote
    await this.prisma.pollVote.create({
      data: {
        pollOptionId: optionId,
        userId,
      },
    });

    // Return updated poll summary
    return this.getPollDetails(pollId, userId);
  }

  async getPollDetails(pollId: string, currentUserId?: string) {
    const poll = await this.prisma.poll.findUnique({
      where: { id: pollId },
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
    });

    if (!poll) {
      throw new NotFoundException('Polling tidak ditemukan');
    }

    const totalVotes = poll.options.reduce((sum, opt) => sum + opt._count.votes, 0);

    return {
      id: poll.id,
      eventId: poll.eventId,
      question: poll.question,
      totalVotes,
      options: poll.options.map((opt) => ({
        id: opt.id,
        text: opt.text,
        votes: opt._count.votes,
        percentage: totalVotes > 0 ? Math.round((opt._count.votes / totalVotes) * 100) : 0,
        hasVoted: currentUserId ? opt.votes.some((v) => v.userId === currentUserId) : false,
      })),
    };
  }

  async triggerIcebreaker(eventId: string, senderId: string) {
    const randomPrompt =
      this.icebreakers[Math.floor(Math.random() * this.icebreakers.length)];

    return this.sendMessage(
      eventId,
      senderId,
      `🧊 [UniMeet Icebreaker] ${randomPrompt}`,
      true,
    );
  }
}
