import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { GeoService } from '../geo/geo.service';
import { Signal, GeoPoint } from '../common/types';

/**
 * Realtime gateway. Pushes signal events to connected clients. In this MVP we
 * broadcast to everyone and let the client filter by its own map bounds; the
 * production version would fan out only to sockets whose last-known location
 * is within the signal's radius (Redis pub/sub keyed by geohash).
 */
@WebSocketGateway({ cors: { origin: true } })
export class RealtimeGateway {
  @WebSocketServer()
  server: Server;

  constructor(private readonly geo: GeoService) {}

  /** Client sends its location; we reply with the signals currently in range. */
  @SubscribeMessage('locate')
  onLocate(
    @MessageBody() body: { lat: number; lng: number; range?: number },
    @ConnectedSocket() client: Socket,
  ) {
    const from: GeoPoint = { lat: body.lat, lng: body.lng };
    const near = this.geo.signalsNear(from, body.range);
    client.emit('signals:snapshot', near);
  }

  /** Called by services when a signal is created — live pin appears. */
  emitSignalCreated(signal: Signal) {
    this.server.emit('signal:created', signal);
  }

  /** Called when a signal is accepted/expired/cancelled — pin updates/removes. */
  emitSignalUpdated(signal: Signal) {
    this.server.emit('signal:updated', signal);
  }
}
