import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger, UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service.js';
import { WsJwtGuard } from '../common/guards/ws-jwt.guard.js';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(private readonly chatService: ChatService) {}

  handleConnection(client: Socket) {
    this.logger.log(`Client connected to WebSocket: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinRoom')
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { eventId: string; userId?: string },
  ) {
    const room = `event:${data.eventId}`;
    await client.join(room);
    this.logger.log(`Client ${client.id} joined squad room ${room}`);
    return { event: 'joinedRoom', room };
  }

  @SubscribeMessage('leaveRoom')
  async handleLeaveRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { eventId: string },
  ) {
    const room = `event:${data.eventId}`;
    await client.leave(room);
    this.logger.log(`Client ${client.id} left squad room ${room}`);
    return { event: 'leftRoom', room };
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { eventId: string; senderId: string; content: string },
  ) {
    try {
      const message = await this.chatService.sendMessage(
        data.eventId,
        data.senderId,
        data.content,
      );

      // Broadcast to all participants in this event room
      this.server.to(`event:${data.eventId}`).emit('newMessage', message);
      return message;
    } catch (error: any) {
      client.emit('error', { message: error.message });
    }
  }

  @SubscribeMessage('votePoll')
  async handleVotePoll(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { pollId: string; optionId: string; userId: string; eventId: string },
  ) {
    try {
      const updatedPoll = await this.chatService.votePoll(
        data.pollId,
        data.optionId,
        data.userId,
      );

      // Broadcast updated poll voting results to the room
      this.server.to(`event:${data.eventId}`).emit('pollUpdated', updatedPoll);
      return updatedPoll;
    } catch (error: any) {
      client.emit('error', { message: error.message });
    }
  }

  @SubscribeMessage('triggerIcebreaker')
  async handleTriggerIcebreaker(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { eventId: string; userId: string },
  ) {
    try {
      const icebreakerMsg = await this.chatService.triggerIcebreaker(
        data.eventId,
        data.userId,
      );

      this.server.to(`event:${data.eventId}`).emit('newMessage', icebreakerMsg);
      return icebreakerMsg;
    } catch (error: any) {
      client.emit('error', { message: error.message });
    }
  }
}
