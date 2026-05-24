import { Injectable, Inject, Logger } from '@nestjs/common';
import { Pool } from 'pg';
import { OrderRepository } from '../../domain/order.repository.interface';
import { Order, OrderItem } from '../../domain/order.entity';
import { PG_POOL } from '../../infrastructure/database.provider';

@Injectable()
export class PostgresOrderRepository implements OrderRepository {
  private readonly logger = new Logger(PostgresOrderRepository.name);

  constructor(@Inject(PG_POOL) private readonly pool: Pool) {
    this.logger.log = () => {};
  }

  async save(order: Order): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at)
         VALUES ($1, $2, $3, $4, $5)`,
        [order.orderId, order.customerId, order.totalAmount, order.itemsCount, order.createdAt],
      );

      for (const item of order.items) {
        await client.query(
          `INSERT INTO order_items (order_id, product_id, quantity, price)
           VALUES ($1, $2, $3, $4)`,
          [order.orderId, item.productId, item.quantity, item.price],
        );
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async findById(orderId: string): Promise<Order | null> {
    const result = await this.pool.query(
      `SELECT order_id, customer_id, total_amount, items_count, created_at
       FROM orders WHERE order_id = $1`,
      [orderId],
    );

    if (result.rows.length === 0) {
      return null;
    }

    const row = result.rows[0];

    const itemsResult = await this.pool.query(
      `SELECT product_id, quantity, price FROM order_items WHERE order_id = $1`,
      [orderId],
    );

    const items = itemsResult.rows.map(
      r => new OrderItem(r.product_id, r.quantity, parseFloat(r.price)),
    );

    const createdAt = row.created_at instanceof Date
      ? row.created_at.toISOString().replace(/\.\d{3}Z$/, 'Z')
      : row.created_at;

    return new Order(
      row.order_id,
      row.customer_id,
      items,
      parseFloat(row.total_amount),
      row.items_count,
      createdAt,
    );
  }
}
