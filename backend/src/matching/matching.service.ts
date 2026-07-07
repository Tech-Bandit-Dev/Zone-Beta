import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InMemoryStore } from '../common/in-memory.store';
import { Signal, SignalStatus } from '../common/types';
import { RealtimeGateway } from '../realtime/realtime.gateway';

/**
 * Matching / transaction service. Handles the accept flow. Payment and
 * post-match coordination (chat lives on the client for now) would hang off
 * this service later.
 */
@Injectable()
export class MatchingService {
  constructor(
    private readonly store: InMemoryStore,
    private readonly realtime: RealtimeGateway,
  ) {}

  accept(signalId: string, accepterId: string): Signal {
    const signal = this.store.signals.get(signalId);
    if (!signal) throw new NotFoundException('Signal not found');

    if (signal.status !== SignalStatus.ACTIVE) {
      throw new BadRequestException('Signal is no longer active');
    }
    if (signal.posterId === accepterId) {
      throw new BadRequestException('Cannot accept your own signal');
    }

    signal.status = SignalStatus.ACCEPTED;
    signal.acceptedById = accepterId;
    this.store.signals.set(signal.id, signal);

    this.realtime.emitSignalUpdated(signal);
    return signal;
  }
}
