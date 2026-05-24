from dataclasses import dataclass, field
from datetime import datetime, timezone
from uuid import uuid4


@dataclass
class OrderItem:
    product_id: str
    quantity: int
    price: float

    def subtotal(self) -> float:
        return self.quantity * self.price


@dataclass
class Order:
    order_id: str
    customer_id: str
    items: list[OrderItem]
    total_amount: float
    items_count: int
    created_at: datetime

    @staticmethod
    def create(customer_id: str, items: list[OrderItem]) -> "Order":
        total_amount = sum(item.subtotal() for item in items)
        items_count = sum(item.quantity for item in items)
        return Order(
            order_id=str(uuid4()),
            customer_id=customer_id,
            items=items,
            total_amount=total_amount,
            items_count=items_count,
            created_at=datetime.now(timezone.utc),
        )
