import { Injectable } from '@nestjs/common';
import { InMemoryStore } from '../common/in-memory.store';
import { distanceMeters } from '../common/geo.util';
import { GeoPoint, Signal, SignalStatus } from '../common/types';

export interface SignalWithDistance extends Signal {
  distanceMeters: number;
}

/**
 * Geo / proximity service. Answers "which active signals are within range of
 * this point". A signal is visible if the viewer is inside the signal's own
 * broadcast radius. Backed by haversine now; swap for PostGIS/Redis GEO later.
 */
@Injectable()
export class GeoService {
  constructor(private readonly store: InMemoryStore) {}

  /**
   * @param from     viewer location
   * @param maxRange optional cap (viewer's chosen search radius, meters)
   */
  signalsNear(from: GeoPoint, maxRange?: number): SignalWithDistance[] {
    const now = Date.now();
    const results: SignalWithDistance[] = [];

    for (const signal of this.store.signals.values()) {
      if (signal.status !== SignalStatus.ACTIVE) continue;
      if (new Date(signal.expiresAt).getTime() <= now) continue;

      const d = distanceMeters(from, signal.location);

      // Visible if within the signal's broadcast radius AND within the
      // viewer's chosen search range (if provided).
      const withinSignal = d <= signal.radiusMeters;
      const withinSearch = maxRange ? d <= maxRange : true;
      if (withinSignal && withinSearch) {
        results.push({ ...signal, distanceMeters: Math.round(d) });
      }
    }

    return results.sort((a, b) => a.distanceMeters - b.distanceMeters);
  }
}
