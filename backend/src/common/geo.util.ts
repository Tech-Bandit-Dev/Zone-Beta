import { GeoPoint } from './types';

/**
 * Haversine distance in meters between two lat/lng points.
 * Used for radius matching until we swap in PostGIS / Redis GEO.
 */
export function distanceMeters(a: GeoPoint, b: GeoPoint): number {
  const R = 6371000; // earth radius in meters
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);

  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}
