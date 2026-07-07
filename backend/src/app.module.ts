import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CommonModule } from './common/common.module';
import { AuthModule } from './auth/auth.module';
import { IdentityModule } from './identity/identity.module';
import { SignalModule } from './signal/signal.module';
import { GeoModule } from './geo/geo.module';
import { RealtimeModule } from './realtime/realtime.module';
import { MatchingModule } from './matching/matching.module';

/**
 * Root module. Each feature module below is a self-contained "service"
 * (auth, identity/KYC, signal, geo, realtime, matching). Kept as a modular
 * monolith for now — each module can later be extracted into its own
 * deployable microservice with minimal changes.
 */
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CommonModule,
    AuthModule,
    IdentityModule,
    SignalModule,
    GeoModule,
    RealtimeModule,
    MatchingModule,
  ],
})
export class AppModule {}
