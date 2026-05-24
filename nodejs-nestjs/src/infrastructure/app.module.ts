import { Module, Logger } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OrderController } from '../adapter/in/order.controller';
import { CreateOrderUseCase } from '../application/create-order.use-case';
import { PostgresOrderRepository } from '../adapter/out/postgres-order.repository';
import { ORDER_REPOSITORY } from '../domain/order.repository.interface';
import { databaseProvider } from './database.provider';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [OrderController],
  providers: [
    databaseProvider,
    {
      provide: ORDER_REPOSITORY,
      useClass: PostgresOrderRepository,
    },
    CreateOrderUseCase,
  ],
})
export class AppModule {}
