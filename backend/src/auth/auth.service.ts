import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { v4 as uuid } from 'uuid';
import { InMemoryStore } from '../common/in-memory.store';
import { UserProfile, VerificationTier } from '../common/types';
import { GoogleSignInDto, RequestOtpDto, VerifyOtpDto } from './auth.dto';

interface PendingOtp {
  code: string;
  name?: string;
  expiresAt: number;
}

@Injectable()
export class AuthService {
  // phone -> pending OTP challenge
  private readonly pending = new Map<string, PendingOtp>();
  private readonly googleClient: OAuth2Client;

  constructor(
    private readonly store: InMemoryStore,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {
    this.googleClient = new OAuth2Client(this.config.get<string>('GOOGLE_CLIENT_ID'));
  }

  /**
   * Request an OTP. In mock mode we return a fixed code so the frontend flow
   * works without an SMS provider. Wire Twilio / MSG91 here for production.
   */
  requestOtp(dto: RequestOtpDto): { sent: true; devCode?: string } {
    const mock = this.config.get<string>('OTP_MOCK_MODE') !== 'false';
    const code = mock ? '123456' : this.randomCode();

    this.pending.set(dto.phone, {
      code,
      name: dto.name,
      expiresAt: Date.now() + 5 * 60 * 1000,
    });

    // In mock mode we surface the code so you can test end to end.
    return mock ? { sent: true, devCode: code } : { sent: true };
  }

  /**
   * Verify an OTP and return a JWT + profile. In mock mode any 6-digit code
   * is accepted. Creates the user on first successful verify (signup),
   * otherwise returns the existing user (login).
   */
  verifyOtp(dto: VerifyOtpDto): { token: string; user: UserProfile } {
    const mock = this.config.get<string>('OTP_MOCK_MODE') !== 'false';
    const challenge = this.pending.get(dto.phone);

    const validCode = mock
      ? /^\d{6}$/.test(dto.code)
      : challenge && challenge.code === dto.code && challenge.expiresAt > Date.now();

    if (!validCode) {
      throw new UnauthorizedException('Invalid or expired code');
    }

    let user = this.findByPhone(dto.phone);
    if (!user) {
      user = {
        id: uuid(),
        name: challenge?.name ?? 'Zone user',
        phone: dto.phone,
        rating: 5.0,
        verification: VerificationTier.PHONE,
        createdAt: new Date().toISOString(),
      };
      this.store.users.set(user.id, user);
    }

    this.pending.delete(dto.phone);

    const token = this.jwt.sign({ sub: user.id, phone: user.phone });
    return { token, user };
  }

  /**
   * Verify a Google ID token (never trust it unverified) and return a JWT +
   * profile, creating the user on first sign-in. Matches existing accounts
   * by googleId first, then by email, so a user who originally signed up by
   * phone and later uses Google with the same email gets merged rather than
   * duplicated.
   */
  async googleSignIn(dto: GoogleSignInDto): Promise<{ token: string; user: UserProfile }> {
    const audience = this.config.get<string>('GOOGLE_CLIENT_ID');
    if (!audience) {
      throw new UnauthorizedException(
        'Google sign-in is not configured on the server (missing GOOGLE_CLIENT_ID).',
      );
    }

    let payload;
    try {
      const ticket = await this.googleClient.verifyIdToken({ idToken: dto.idToken, audience });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Invalid Google token');
    }
    if (!payload?.sub || !payload.email) {
      throw new UnauthorizedException('Invalid Google token');
    }

    let user = this.findByGoogleId(payload.sub) ?? this.findByEmail(payload.email);
    if (!user) {
      user = {
        id: uuid(),
        name: payload.name ?? payload.email.split('@')[0],
        email: payload.email,
        googleId: payload.sub,
        avatarUrl: payload.picture,
        rating: 5.0,
        verification: VerificationTier.NONE,
        createdAt: new Date().toISOString(),
      };
      this.store.users.set(user.id, user);
    } else if (!user.googleId) {
      // Existing phone-signup user linking their Google account.
      user.googleId = payload.sub;
      user.email = payload.email;
      user.avatarUrl ??= payload.picture;
    }

    const token = this.jwt.sign({ sub: user.id, email: user.email });
    return { token, user };
  }

  private findByPhone(phone: string): UserProfile | undefined {
    for (const u of this.store.users.values()) {
      if (u.phone === phone) return u;
    }
    return undefined;
  }

  private findByGoogleId(googleId: string): UserProfile | undefined {
    for (const u of this.store.users.values()) {
      if (u.googleId === googleId) return u;
    }
    return undefined;
  }

  private findByEmail(email: string): UserProfile | undefined {
    for (const u of this.store.users.values()) {
      if (u.email === email) return u;
    }
    return undefined;
  }

  private randomCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}
