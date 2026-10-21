import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';
import { HttpExceptionFilter } from './common/filters/http-exception.filter.js';

async function bootstrap() {
  const logger = new Logger('UniMeetBootstrap');
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global API Prefix
  app.setGlobalPrefix('api/v1');

  // Global Validation Pipe with strict DTO rules
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global Custom Exception Filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Swagger OpenAPI Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('UniMeet Backend API')
    .setDescription(
      'RESTful & WebSocket API untuk UniMeet — Platform Komunitas & Aktivitas Kampus Khusus Mahasiswa BINUS University',
    )
    .setVersion('1.0.0')
    .addBearerAuth()
    .addTag('Auth', 'Verifikasi email kampus (@binus.ac.id) & login SSO Binusmaya')
    .addTag('Users', 'Profil mahasiswa, Flazz digital pass, dan Kating & Senior Connect')
    .addTag('Events', 'Host aktivitas, feed filter, RSVP squad & digital QR turnstile passes')
    .addTag('Chat', 'WebSocket & REST squad chat, in-chat polling, dan automated icebreakers')
    .addTag('Notifications', 'Push alerts untuk join squad dan jadwal')
    .addTag('Subscriptions', 'UniMeet Campus Pro tier & accessories')
    .addTag('Sponsorships', 'Promo vendor lokal, arena badminton, cafe di sekitar kampus')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'UniMeet API Docs — BINUS Campus Social Hub',
  });

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  logger.log(`🚀 UniMeet Backend Service is running on: http://localhost:${port}/api/v1`);
  logger.log(`📚 Swagger OpenAPI documentation available at: http://localhost:${port}/api/docs`);
}

await bootstrap();
