import time

from psycopg2 import pool as psycopg2_pool
from psycopg2.pool import ThreadedConnectionPool

from src.domain.order import Order
from src.domain.order_repository import OrderRepository


def _get_conn_with_retry(pool: ThreadedConnectionPool, retries: int = 5, delay: float = 0.05):
    """Obtiene una conexión del pool con retry para evitar PoolError bajo alta carga."""
    for attempt in range(retries):
        try:
            return pool.getconn()
        except psycopg2_pool.PoolError:
            if attempt == retries - 1:
                raise
            time.sleep(delay * (attempt + 1))
    raise psycopg2_pool.PoolError("connection pool exhausted after retries")


class PostgresOrderRepository(OrderRepository):
    def __init__(self, pool: ThreadedConnectionPool) -> None:
        self._pool = pool

    def save(self, order: Order) -> None:
        conn = _get_conn_with_retry(self._pool)
        try:
            conn.autocommit = False
            cur = conn.cursor()

            cur.execute(
                """INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at)
                   VALUES (%s, %s, %s, %s, %s)""",
                (order.order_id, order.customer_id, order.total_amount, order.items_count, order.created_at),
            )

            for item in order.items:
                cur.execute(
                    """INSERT INTO order_items (order_id, product_id, quantity, price)
                       VALUES (%s, %s, %s, %s)""",
                    (order.order_id, item.product_id, item.quantity, item.price),
                )

            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            cur.close()
            self._pool.putconn(conn)

    def find_by_id(self, order_id: str) -> Order | None:
        conn = _get_conn_with_retry(self._pool)
        try:
            cur = conn.cursor()
            cur.execute(
                """SELECT order_id, customer_id, total_amount, items_count, created_at
                   FROM orders WHERE order_id = %s""",
                (order_id,),
            )
            row = cur.fetchone()
            if row is None:
                return None

            cur.execute(
                """SELECT product_id, quantity, price
                   FROM order_items WHERE order_id = %s""",
                (order_id,),
            )
            from src.domain.order import OrderItem

            items = [
                OrderItem(product_id=r[0], quantity=r[1], price=float(r[2]))
                for r in cur.fetchall()
            ]

            return Order(
                order_id=row[0],
                customer_id=row[1],
                items=items,
                total_amount=float(row[2]),
                items_count=row[3],
                created_at=row[4],
            )
        finally:
            cur.close()
            self._pool.putconn(conn)
