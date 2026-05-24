from dataclasses import dataclass


@dataclass
class CreateOrderItemInput:
    productId: str
    quantity: int
    price: float


@dataclass
class CreateOrderInput:
    customerId: str
    items: list[CreateOrderItemInput]


@dataclass
class CreateOrderOutput:
    orderId: str
    customerId: str
    totalAmount: float
    itemsCount: int
    createdAt: str
