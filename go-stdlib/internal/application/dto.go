package application

type CreateOrderItemInput struct {
	ProductID string  `json:"productId"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
}

type CreateOrderInput struct {
	CustomerID string                  `json:"customerId"`
	Items      []CreateOrderItemInput  `json:"items"`
}

type CreateOrderOutput struct {
	OrderID     string  `json:"orderId"`
	CustomerID  string  `json:"customerId"`
	TotalAmount float64 `json:"totalAmount"`
	ItemsCount  int     `json:"itemsCount"`
	CreatedAt   string  `json:"createdAt"`
}
