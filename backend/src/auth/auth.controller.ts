import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { GoogleSignInDto, RequestOtpDto, VerifyOtpDto } from './auth.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  // Used by both signup (with name) and login (without).
  @Post('request-otp')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.auth.requestOtp(dto);
  }

  @Post('verify-otp')
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(dto);
  }

  // Used by both Google sign-up and sign-in — one Google account is one
  // identity, so there's no separate "mode" like the phone flow needs.
  @Post('google')
  googleSignIn(@Body() dto: GoogleSignInDto) {
    return this.auth.googleSignIn(dto);
  }
}
