import { Controller, Param, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MatchingService } from './matching.service';

@Controller('signals')
@UseGuards(JwtAuthGuard)
export class MatchingController {
  constructor(private readonly matching: MatchingService) {}

  @Post(':id/accept')
  accept(@Req() req: Request, @Param('id') id: string) {
    const userId = (req as any).user.sub as string;
    return this.matching.accept(id, userId);
  }
}
