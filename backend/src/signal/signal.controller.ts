import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SignalService } from './signal.service';
import { CreateSignalDto } from './signal.dto';

@Controller('signals')
export class SignalController {
  constructor(private readonly signals: SignalService) {}

  // Public read so the map can load; auth still recommended in production.
  @Get('nearby')
  nearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('range') range?: string,
  ) {
    return this.signals.nearby(
      parseFloat(lat),
      parseFloat(lng),
      range ? parseInt(range, 10) : undefined,
    );
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@Req() req: Request, @Body() dto: CreateSignalDto) {
    const userId = (req as any).user.sub as string;
    return this.signals.create(userId, dto);
  }
}
