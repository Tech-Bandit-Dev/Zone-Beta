import { IsOptional, IsString, Length, Matches } from 'class-validator';

export class RequestOtpDto {
  @IsString()
  @Matches(/^\+?[1-9]\d{6,14}$/, { message: 'phone must be E.164-ish' })
  phone: string;

  // Present on signup, absent on login.
  @IsOptional()
  @IsString()
  @Length(1, 60)
  name?: string;
}

export class VerifyOtpDto {
  @IsString()
  @Matches(/^\+?[1-9]\d{6,14}$/)
  phone: string;

  @IsString()
  @Length(6, 6, { message: 'otp must be 6 digits' })
  code: string;
}

export class GoogleSignInDto {
  // The ID token from GoogleSignInAuthentication.idToken on the client —
  // verified server-side against GOOGLE_CLIENT_ID, never trusted as-is.
  @IsString()
  idToken: string;
}
