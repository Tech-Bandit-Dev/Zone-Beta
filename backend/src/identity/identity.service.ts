import { Injectable, NotFoundException } from '@nestjs/common';
import { InMemoryStore } from '../common/in-memory.store';
import { UserProfile, VerificationTier } from '../common/types';

/**
 * Identity / KYC service. Owns the user profile and the verification tier.
 * Phone verification happens at auth; KYC (Aadhaar / DigiLocker / a provider
 * like Signzy or HyperVerge) would upgrade the tier here and unlock trust.
 */
@Injectable()
export class IdentityService {
  constructor(private readonly store: InMemoryStore) {}

  getProfile(userId: string): UserProfile {
    const user = this.store.users.get(userId);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  updateName(userId: string, name: string): UserProfile {
    const user = this.getProfile(userId);
    user.name = name;
    this.store.users.set(userId, user);
    return user;
  }

  /**
   * Mock KYC: instantly marks the user as KYC-verified. Replace the body with
   * a real provider callback/webhook in production.
   */
  submitKyc(userId: string): UserProfile {
    const user = this.getProfile(userId);
    user.verification = VerificationTier.KYC;
    this.store.users.set(userId, user);
    return user;
  }
}
