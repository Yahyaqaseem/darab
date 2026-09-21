import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RealtimeGateway.name);
  private driverLocations = new Map<string, { lat: number; lng: number; bearing?: number; roadSegment?: string; socketId: string }>();

  handleConnection(client: Socket) {
    this.logger.log(`🚗 Driver connected to realtime hub: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`🛑 Driver disconnected: ${client.id}`);
    this.driverLocations.delete(client.id);
  }

  @SubscribeMessage('update_location')
  handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { lat: number; lng: number; bearing?: number; roadSegment?: string },
  ) {
    this.driverLocations.set(client.id, {
      ...data,
      socketId: client.id,
    });

    if (data.roadSegment) {
      client.join(`segment:${data.roadSegment}`);
    }
  }

  @SubscribeMessage('join_road_segment')
  handleJoinSegment(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { segmentId: string },
  ) {
    client.join(`segment:${data.segmentId}`);
    this.logger.log(`Client ${client.id} joined segment room: ${data.segmentId}`);
    return { success: true, joined: data.segmentId };
  }

  private clientLastChatTime = new Map<string, number>();

  @SubscribeMessage('send_road_chat')
  handleRoadChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { segmentId: string; message: string; senderAlias?: string },
  ) {
    const now = Date.now();
    const last = this.clientLastChatTime.get(client.id) || 0;
    if (now - last < 3000) {
      return { success: false, error: 'يرجى الانتظار 3 ثوانٍ بين الرسائل لمنع التشتت أثناء القيادة' };
    }
    this.clientLastChatTime.set(client.id, now);

    const cleanMessage = (data.message || '').trim().slice(0, 180);
    if (!cleanMessage || cleanMessage.length < 2) {
      return { success: false, error: 'الرسالة قصيرة جداً أو فارغة' };
    }

    const chatPayload = {
      id: `msg-${Date.now()}`,
      senderAlias: data.senderAlias || 'سائق على الطريق',
      message: cleanMessage,
      timestamp: new Date().toISOString(),
      segmentId: data.segmentId || 'default-road',
    };
    this.server.to(`segment:${chatPayload.segmentId}`).emit('road_chat_message', chatPayload);
    return { success: true, message: chatPayload };
  }

  // Helper broadcast methods used by services
  broadcastNewReport(report: any) {
    if (this.server) {
      this.server.emit('new_road_report', report);
    }
  }

  broadcastReportConfirmation(confirmation: any) {
    if (this.server) {
      this.server.emit('report_confirmed', confirmation);
    }
  }

  broadcastRoadCall(roadCall: any, segmentId?: string) {
    if (this.server) {
      if (segmentId) {
        this.server.to(`segment:${segmentId}`).emit('new_road_call', roadCall);
      }
      this.server.emit('new_road_call', roadCall);
    }
  }

  broadcastRoadCallAnswer(answerUpdate: any) {
    if (this.server) {
      this.server.emit('road_call_answer_update', answerUpdate);
    }
  }
}
