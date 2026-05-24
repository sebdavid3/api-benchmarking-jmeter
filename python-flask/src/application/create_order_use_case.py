from src.application.dto import CreateOrderInput, CreateOrderOutput
from src.domain.order import Order, OrderItem
from src.domain.order_repository import OrderRepository


class CreateOrderUseCase:
    def __init__(self, repo: OrderRepository) -> None:
        self._repo = repo

    def execute(self, input_dto: CreateOrderInput) -> CreateOrderOutput:
        if not input_dto.customerId:
            raise ValueError("customerId is required")
        if not input_dto.items:
            raise ValueError("items must not be empty")

        items = []
        for i, item in enumerate(input_dto.items):
            if not item.productId:
                raise ValueError(f"item[{i}].productId is required")
            if item.quantity <= 0:
                raise ValueError(f"item[{i}].quantity must be greater than 0")
            if item.price < 0:
                raise ValueError(f"item[{i}].price must be >= 0")
            items.append(
                OrderItem(
                    product_id=item.productId,
                    quantity=item.quantity,
                    price=item.price,
                )
            )

        order = Order.create(input_dto.customerId, items)
        self._repo.save(order)

        return CreateOrderOutput(
            orderId=order.order_id,
            customerId=order.customer_id,
            totalAmount=order.total_amount,
            itemsCount=order.items_count,
            createdAt=order.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        )
