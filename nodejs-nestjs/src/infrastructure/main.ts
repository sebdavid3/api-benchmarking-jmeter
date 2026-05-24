import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn'],
  });

  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
    disableErrorMessages: false,
  }));

  app.getHttpAdapter().get('/health', (_req: any, res: any) => {
    res.status(200).send('OK');
  });

  await app.listen(5002, '0.0.0.0');
  logger.log('Server listening on port 5002');
}
bootstrap();
