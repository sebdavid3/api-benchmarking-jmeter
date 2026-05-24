package application

import (
	"context"
	"fmt"

	"github.com/benchmark/orders/internal/domain"
)

type CreateOrderUseCase struct {
	repo domain.OrderRepository
}

func NewCreateOrderUseCase(repo domain.OrderRepository) *CreateOrderUseCase {
	return &CreateOrderUseCase{repo: repo}
}

func (uc *CreateOrderUseCase) Execute(ctx context.Context, input CreateOrderInput) (*CreateOrderOutput, error) {
	if input.CustomerID == "" {
		return nil, fmt.Errorf("customerId is required")
	}
	if len(input.Items) == 0 {
		return nil, fmt.Errorf("items must not be empty")
	}

	items := make([]domain.OrderItem, len(input.Items))
	for i, item := range input.Items {
		if item.ProductID == "" {
			return nil, fmt.Errorf("item[%d].productId is required", i)
		}
		if item.Quantity <= 0 {
			return nil, fmt.Errorf("item[%d].quantity must be greater than 0", i)
		}
		if item.Price < 0 {
			return nil, fmt.Errorf("item[%d].price must be >= 0", i)
		}
		items[i] = domain.OrderItem{
			ProductID: item.ProductID,
			Quantity:  item.Quantity,
			Price:     item.Price,
		}
	}

	order := domain.NewOrder(input.CustomerID, items)

	if err := uc.repo.Save(ctx, order); err != nil {
		return nil, fmt.Errorf("failed to save order: %w", err)
	}

	return &CreateOrderOutput{
		OrderID:     order.OrderID,
		CustomerID:  order.CustomerID,
		TotalAmount: order.TotalAmount,
		ItemsCount:  order.ItemsCount,
		CreatedAt:   order.CreatedAt.Format("2006-01-02T15:04:05Z"),
	}, nil
}
