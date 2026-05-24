package domain

import "context"

type OrderRepository interface {
	Save(ctx context.Context, order Order) error
	FindByID(ctx context.Context, orderID string) (*Order, error)
}
