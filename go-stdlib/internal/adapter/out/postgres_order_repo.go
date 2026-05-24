package out

import (
	"context"

	"github.com/benchmark/orders/internal/domain"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresOrderRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresOrderRepository(pool *pgxpool.Pool) *PostgresOrderRepository {
	return &PostgresOrderRepository{pool: pool}
}

func (r *PostgresOrderRepository) Save(ctx context.Context, order domain.Order) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx,
		`INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at)
		 VALUES ($1, $2, $3, $4, $5)`,
		order.OrderID, order.CustomerID, order.TotalAmount, order.ItemsCount, order.CreatedAt,
	)
	if err != nil {
		return err
	}

	for _, item := range order.Items {
		_, err = tx.Exec(ctx,
			`INSERT INTO order_items (order_id, product_id, quantity, price)
			 VALUES ($1, $2, $3, $4)`,
			order.OrderID, item.ProductID, item.Quantity, item.Price,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *PostgresOrderRepository) FindByID(ctx context.Context, orderID string) (*domain.Order, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT order_id, customer_id, total_amount, items_count, created_at
		 FROM orders WHERE order_id = $1`, orderID,
	)

	var order domain.Order
	err := row.Scan(&order.OrderID, &order.CustomerID, &order.TotalAmount, &order.ItemsCount, &order.CreatedAt)
	if err != nil {
		return nil, err
	}

	rows, err := r.pool.Query(ctx,
		`SELECT product_id, quantity, price FROM order_items WHERE order_id = $1`, orderID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var item domain.OrderItem
		if err := rows.Scan(&item.ProductID, &item.Quantity, &item.Price); err != nil {
			return nil, err
		}
		order.Items = append(order.Items, item)
	}

	return &order, nil
}
