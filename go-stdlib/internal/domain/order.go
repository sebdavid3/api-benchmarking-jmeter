package domain

import (
	"time"

	"github.com/google/uuid"
)

type OrderItem struct {
	ProductID string
	Quantity  int
	Price     float64
}

func (oi OrderItem) Subtotal() float64 {
	return float64(oi.Quantity) * oi.Price
}

type Order struct {
	OrderID     string
	CustomerID  string
	Items       []OrderItem
	TotalAmount float64
	ItemsCount  int
	CreatedAt   time.Time
}

func NewOrder(customerID string, items []OrderItem) Order {
	var total float64
	var count int
	for _, item := range items {
		total += item.Subtotal()
		count += item.Quantity
	}
	return Order{
		OrderID:     uuid.New().String(),
		CustomerID:  customerID,
		Items:       items,
		TotalAmount: total,
		ItemsCount:  count,
		CreatedAt:   time.Now().UTC(),
	}
}
