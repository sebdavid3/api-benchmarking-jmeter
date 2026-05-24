export class OrderItem {
  constructor(
    public readonly productId: string,
    public readonly quantity: number,
    public readonly price: number,
  ) {}

  subtotal(): number {
    return this.quantity * this.price;
  }
}

export class Order {
  constructor(
    public readonly orderId: string,
    public readonly customerId: string,
    public readonly items: OrderItem[],
    public readonly totalAmount: number,
    public readonly itemsCount: number,
    public readonly createdAt: string,
  ) {}
}

import { v4 as uuidv4 } from 'uuid';

export function createOrder(customerId: string, items: OrderItem[]): Order {
  const totalAmount = items.reduce((sum, item) => sum + item.subtotal(), 0);
  const itemsCount = items.reduce((sum, item) => sum + item.quantity, 0);

  return new Order(
    uuidv4(),
    customerId,
    items,
    totalAmount,
    itemsCount,
    new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
  );
}
