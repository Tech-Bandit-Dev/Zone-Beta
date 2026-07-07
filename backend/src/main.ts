import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);

  // Global validation so DTOs are enforced everywhere.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // CORS so the Flutter app can call the API and connect over WebSocket.
  const origin = config.get<string>('CORS_ORIGIN') ?? '*';
  app.enableCors({
    origin: origin === '*' ? true : origin.split(','),
    credentials: true,
  });

  app.setGlobalPrefix('api');

  const port = config.get<number>('PORT') ?? 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`Zone backend running on http://localhost:${port}/api`);
}
bootstrap();
