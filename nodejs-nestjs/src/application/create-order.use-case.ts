import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { CreateOrderInput, CreateOrderOutput } from './dto';
import { OrderItem, createOrder } from '../domain/order.entity';
import { OrderRepository, ORDER_REPOSITORY } from '../domain/order.repository.interface';

@Injectable()
export class CreateOrderUseCase {
  constructor(
    @Inject(ORDER_REPOSITORY) private readonly repo: OrderRepository,
  ) {}

  async execute(input: CreateOrderInput): Promise<CreateOrderOutput> {
    if (!input.customerId) {
      throw new BadRequestException('customerId is required');
    }
    if (!input.items || input.items.length === 0) {
      throw new BadRequestException('items must not be empty');
    }

    const items: OrderItem[] = input.items.map((item, i) => {
      if (!item.productId) {
        throw new BadRequestException(`item[${i}].productId is required`);
      }
      if (item.quantity <= 0) {
        throw new BadRequestException(`item[${i}].quantity must be greater than 0`);
      }
      if (item.price < 0) {
        throw new BadRequestException(`item[${i}].price must be >= 0`);
      }
      return new OrderItem(item.productId, item.quantity, item.price);
    });

    const order = createOrder(input.customerId, items);
    await this.repo.save(order);

    return {
      orderId: order.orderId,
      customerId: order.customerId,
      totalAmount: order.totalAmount,
      itemsCount: order.itemsCount,
      createdAt: order.createdAt,
    };
  }
}
