/**
 * Shared domain types used across modules.
 * The `Signal` is the core primitive of Zone: a geo-tagged, time-boxed,
 * radius-scoped post that nearby users can see and accept.
 */

export enum SignalType {
  RIDE = 'ride',
  ERRAND = 'errand',
  HANDOFF = 'handoff',
}

export enum SignalStatus {
  ACTIVE = 'active',
  ACCEPTED = 'accepted',
  EXPIRED = 'expired',
  CANCELLED = 'cancelled',
}

export interface GeoPoint {
  lat: number;
  lng: number;
}

export interface Signal {
  id: string;
  posterId: string;
  message: string;
  type: SignalType;
  radiusMeters: number; // 250 | 500 | 1000
  location: GeoPoint;
  status: SignalStatus;
  createdAt: string; // ISO
  expiresAt: string; // ISO
  acceptedById?: string;
}

export enum VerificationTier {
  NONE = 'none',
  PHONE = 'phone',
  KYC = 'kyc',
}

export interface UserProfile {
  id: string;
  name: string;
  // Phone-auth users have phone but no email/googleId; Google-auth users have
  // email/googleId but may have no phone. One of the two identities is
  // always present.
  phone?: string;
  email?: string;
  googleId?: string;
  avatarUrl?: string;
  rating: number;
  verification: VerificationTier;
  createdAt: string;
}
