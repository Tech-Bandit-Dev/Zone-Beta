import { Module } from '@nestjs/common';
import { GeoModule } from '../geo/geo.module';
import { RealtimeGateway } from './realtime.gateway';

@Module({
  imports: [GeoModule],
  providers: [RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
