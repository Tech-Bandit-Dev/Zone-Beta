import { IsEmail, IsOptional, IsString, Length } from 'class-validator';

export class RequestOtpDto {
  @IsEmail()
  email: string;

  // Present on signup, absent on login.
  @IsOptional()
  @IsString()
  @Length(1, 60)
  name?: string;
}

export class VerifyOtpDto {
  @IsEmail()
  email: string;

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
