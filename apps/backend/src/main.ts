import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap() {
  const logger = new Logger('DARB_API');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Serve Interactive Mobile Web App Simulator
  app.useStaticAssets(join(__dirname, '..', 'public'));

  // Enable CORS for mobile clients and web dashboards
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global prefix
  app.setGlobalPrefix('api/v1');

  // Request validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  // Swagger OpenAPI Documentation
  const config = new DocumentBuilder()
    .setTitle('دَرْب — DARB API')
    .setDescription('منظومة الملاحة وبيانات الطرق الحية الذكية ومجتمع السائقين في العراق')
    .setVersion('1.0.0')
    .addBearerAuth()
    .addTag('المصادقة وتسجيل الدخول (Auth)')
    .addTag('بلاغات الطرق الحية (Road Reports)')
    .addTag('نداء الطريق (Road Call System)')
    .addTag('محطات الوقود والأسعار (Fuel Stations)')
    .addTag('الملاحة وتوجيه المسارات (Smart Navigation)')
    .addTag('دليل الأماكن والخدمات (Places & Services)')
    .addTag('الرحلات وإحصائيات القيادة (Trips & Statistics)')
    .addTag('المستخدمين والمرآب (Users & Garage)')
    .addTag('السمعة والأوسمة (Gamification & Badges)')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = process.env.PORT || 4000;
  await app.listen(port);

  logger.log(`🚀 DARB Backend API is running on: http://localhost:${port}/api/v1`);
  logger.log(`📖 Swagger API Docs available at: http://localhost:${port}/docs`);
}

bootstrap();
