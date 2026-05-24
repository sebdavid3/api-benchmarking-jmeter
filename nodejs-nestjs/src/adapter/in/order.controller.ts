import { Controller, Post, Body, HttpCode, Logger } from '@nestjs/common';
import { CreateOrderUseCase } from '../../application/create-order.use-case';
import { CreateOrderInput } from '../../application/dto';

@Controller('api/orders')
export class OrderController {
  private readonly logger = new Logger(OrderController.name);

  constructor(private readonly useCase: CreateOrderUseCase) {
    this.logger.log = () => {};
  }

  @Post()
  @HttpCode(200)
  async create(@Body() input: CreateOrderInput) {
    return this.useCase.execute(input);
  }
}
