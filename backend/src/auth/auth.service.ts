import {
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import * as nodemailer from 'nodemailer';
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
  // email -> pending OTP challenge
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
   * works without a mail server configured. Otherwise we generate a real
   * code and email it.
   */
  async requestOtp(dto: RequestOtpDto): Promise<{ sent: true; devCode?: string }> {
    const mock = this.config.get<string>('OTP_MOCK_MODE') !== 'false';
    const code = mock ? '123456' : this.randomCode();

    this.pending.set(dto.email, {
      code,
      name: dto.name,
      expiresAt: Date.now() + 5 * 60 * 1000,
    });

    // In mock mode we surface the code so you can test end to end.
    if (mock) {
      return { sent: true, devCode: code };
    }

    try {
      await this.sendOtpEmail(dto.email, code);
    } catch (err) {
      // Don't leave a code the user never received sitting around as valid.
      this.pending.delete(dto.email);
      throw err;
    }
    return { sent: true };
  }

  /**
   * Verify an OTP and return a JWT + profile. In mock mode any 6-digit code
   * is accepted. Creates the user on first successful verify (signup),
   * otherwise returns the existing user (login).
   */
  verifyOtp(dto: VerifyOtpDto): { token: string; user: UserProfile } {
    const mock = this.config.get<string>('OTP_MOCK_MODE') !== 'false';
    const challenge = this.pending.get(dto.email);

    const validCode = mock
      ? /^\d{6}$/.test(dto.code)
      : challenge && challenge.code === dto.code && challenge.expiresAt > Date.now();

    if (!validCode) {
      throw new UnauthorizedException('Invalid or expired code');
    }

    let user = this.findByEmail(dto.email);
    if (!user) {
      user = {
        id: uuid(),
        name: challenge?.name ?? 'Zone user',
        email: dto.email,
        rating: 5.0,
        verification: VerificationTier.PHONE,
        createdAt: new Date().toISOString(),
      };
      this.store.users.set(user.id, user);
    }

    this.pending.delete(dto.email);

    const token = this.jwt.sign({ sub: user.id, email: user.email });
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

  /**
   * Sends the OTP over real email via Gmail SMTP. Only called when
   * OTP_MOCK_MODE=false. The OTP itself is generated and verified by this
   * service (see requestOtp/verifyOtp) — Gmail is used purely as the email
   * transport, not as an OTP provider.
   */
  private async sendOtpEmail(email: string, code: string): Promise<void> {
    const user = this.config.get<string>('GMAIL_USER');
    const pass = this.config.get<string>('GMAIL_APP_PASSWORD');

    if (!user || !pass) {
      throw new InternalServerErrorException(
        'Email sending is not configured (missing GMAIL_USER / GMAIL_APP_PASSWORD).',
      );
    }

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user, pass },
    });

    try {
      await transporter.sendMail({
        from: `Zone <${user}>`,
        to: email,
        subject: `${code} is your Zone verification code`,
        text: `Your Zone verification code is ${code}. It expires in 5 minutes.`,
      });
    } catch (err) {
      throw new InternalServerErrorException(
        `Failed to send OTP email: ${(err as Error).message}`,
      );
    }
  }
}
