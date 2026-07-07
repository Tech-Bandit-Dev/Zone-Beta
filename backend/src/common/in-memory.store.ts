import { Injectable } from '@nestjs/common';
import { Signal, UserProfile } from './types';

/**
 * In-memory store. This stands in for the database layer so the whole app
 * runs with zero infra. Replace with PostgreSQL + PostGIS (signals/geo) and
 * Redis (hot geo-index) when wiring real persistence. Keeping it behind one
 * injectable makes that swap localized.
 */
@Injectable()
export class InMemoryStore {
  readonly users = new Map<string, UserProfile>();
  readonly signals = new Map<string, Signal>();
}
