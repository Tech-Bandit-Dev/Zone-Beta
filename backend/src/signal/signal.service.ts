import { Injectable, OnModuleInit } from '@nestjs/common';
import { v4 as uuid } from 'uuid';
import { InMemoryStore } from '../common/in-memory.store';
import {
  Signal,
  SignalStatus,
  SignalType,
  VerificationTier,
} from '../common/types';
import { GeoService } from '../geo/geo.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { CreateSignalDto } from './signal.dto';

/**
 * Signal service — the heart of Zone. Creates and expires signals and emits
 * realtime events so nearby maps update live.
 */
@Injectable()
export class SignalService implements OnModuleInit {
  // Default center for seed data: near a Delhi metro station.
  private readonly seedCenter = { lat: 28.6139, lng: 77.209 };

  constructor(
    private readonly store: InMemoryStore,
    private readonly geo: GeoService,
    private readonly realtime: RealtimeGateway,
  ) {}

  onModuleInit() {
    this.seed();
  }

  create(posterId: string, dto: CreateSignalDto): Signal {
    const now = new Date();
    const signal: Signal = {
      id: uuid(),
      posterId,
      message: dto.message,
      type: dto.type,
      radiusMeters: dto.radiusMeters,
      location: { lat: dto.lat, lng: dto.lng },
      status: SignalStatus.ACTIVE,
      createdAt: now.toISOString(),
      expiresAt: new Date(
        now.getTime() + dto.expiresInMinutes * 60 * 1000,
      ).toISOString(),
    };
    this.store.signals.set(signal.id, signal);
    this.realtime.emitSignalCreated(signal);
    return signal;
  }

  nearby(lat: number, lng: number, range?: number) {
    return this.geo.signalsNear({ lat, lng }, range);
  }

  getById(id: string): Signal | undefined {
    return this.store.signals.get(id);
  }

  /** Seeds a few demo signals + a demo poster so the map isn't empty. */
  private seed() {
    if (this.store.signals.size > 0) return;

    const posterId = 'seed-user';
    if (!this.store.users.has(posterId)) {
      this.store.users.set(posterId, {
        id: posterId,
        name: 'Aarav',
        phone: '+910000000000',
        rating: 4.8,
        verification: VerificationTier.KYC,
        createdAt: new Date().toISOString(),
      });
    }

    const offsets: Array<{
      dLat: number;
      dLng: number;
      type: SignalType;
      msg: string;
      radius: number;
    }> = [
      { dLat: 0.002, dLng: 0.001, type: SignalType.RIDE, msg: 'Sharing cab Delhi to Gurgaon, leaving in 10 min', radius: 500 },
      { dLat: -0.001, dLng: 0.0015, type: SignalType.ERRAND, msg: 'Heading to the pharmacy, can grab something', radius: 250 },
      { dLat: 0.0008, dLng: -0.002, type: SignalType.HANDOFF, msg: 'Giving up my restaurant waitlist spot for 4', radius: 500 },
      { dLat: -0.0015, dLng: -0.001, type: SignalType.RIDE, msg: 'Auto pool to the airport, splitting fare', radius: 1000 },
    ];

    const now = new Date();
    for (const o of offsets) {
      const signal: Signal = {
        id: uuid(),
        posterId,
        message: o.msg,
        type: o.type,
        radiusMeters: o.radius,
        location: {
          lat: this.seedCenter.lat + o.dLat,
          lng: this.seedCenter.lng + o.dLng,
        },
        status: SignalStatus.ACTIVE,
        createdAt: now.toISOString(),
        expiresAt: new Date(now.getTime() + 60 * 60 * 1000).toISOString(),
      };
      this.store.signals.set(signal.id, signal);
    }
  }
}
