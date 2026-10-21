import { CanActivate, ExecutionContext, Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';

@Injectable()
export class WsJwtGuard implements CanActivate {
  private readonly logger = new Logger(WsJwtGuard.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const client: Socket = context.switchToWs().getClient<Socket>();
      const token =
        client.handshake?.auth?.token ||
        client.handshake?.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        throw new WsException('Unauthorized: Missing auth token in socket handshake');
      }

      const secret = this.configService.get<string>('JWT_SECRET') || 'unimeet-binus-jwt-secret-key-2025';
      const payload = await this.jwtService.verifyAsync(token, { secret });
      
      // Attach user payload to socket
      (client as any).user = payload;
      return true;
    } catch (err: any) {
      this.logger.error(`WebSocket authentication failed: ${err.message}`);
      throw new WsException('Unauthorized socket connection');
    }
  }
}
