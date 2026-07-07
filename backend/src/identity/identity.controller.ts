import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { IsString, Length } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IdentityService } from './identity.service';

class UpdateNameDto {
  @IsString()
  @Length(1, 60)
  name: string;
}

@Controller('me')
@UseGuards(JwtAuthGuard)
export class IdentityController {
  constructor(private readonly identity: IdentityService) {}

  @Get()
  getMe(@Req() req: Request) {
    const userId = (req as any).user.sub as string;
    return this.identity.getProfile(userId);
  }

  @Patch('name')
  updateName(@Req() req: Request, @Body() dto: UpdateNameDto) {
    const userId = (req as any).user.sub as string;
    return this.identity.updateName(userId, dto.name);
  }

  @Post('kyc')
  submitKyc(@Req() req: Request) {
    const userId = (req as any).user.sub as string;
    return this.identity.submitKyc(userId);
  }
}
