-- ============================================================
-- Benchmark: API de Órdenes — Esquema de Base de Datos
-- Versión: 1.0
-- Montado en /docker-entrypoint-initdb.d/ para ejecutar al iniciar Postgres
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS orders (
    id            SERIAL         PRIMARY KEY,
    order_id      VARCHAR(50)    UNIQUE NOT NULL,
    customer_id   VARCHAR(50)    NOT NULL,
    total_amount  NUMERIC(10,2)  NOT NULL,
    items_count   INT            NOT NULL,
    created_at    TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id            SERIAL         PRIMARY KEY,
    order_id      VARCHAR(50)    NOT NULL,
    product_id    VARCHAR(50)    NOT NULL,
    quantity      INT            NOT NULL,
    price         NUMERIC(10,2)  NOT NULL,
    CONSTRAINT fk_order_items_order_id
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_orders_order_id
    ON orders(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items(order_id);

COMMIT;
