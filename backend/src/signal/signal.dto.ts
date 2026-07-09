import {
  IsEnum,
  IsIn,
  IsNumber,
  IsString,
  Length,
  Max,
  Min,
} from 'class-validator';
import { SignalType } from '../common/types';

export class CreateSignalDto {
  @IsString()
  @Length(1, 280)
  message: string;

  @IsEnum(SignalType)
  type: SignalType;

  @IsIn([250, 500, 1000, 2000, 3000, 4000, 5000], {
    message:
      'radiusMeters must be one of 250, 500, 1000, 2000, 3000, 4000, 5000',
  })
  radiusMeters: number;

  @IsNumber()
  @Min(-90)
  @Max(90)
  lat: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng: number;

  // Minutes until expiry: 15 | 30 | 60 | 120 | 180 | 240 | 300 | 360 (6 hr max).
  @IsIn([15, 30, 60, 120, 180, 240, 300, 360])
  expiresInMinutes: number;
}

export class NearbyQueryDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng: number;

  // Optional viewer search range.
  @IsIn([250, 500, 1000, 2000, 3000, 4000, 5000])
  range?: number;
}
