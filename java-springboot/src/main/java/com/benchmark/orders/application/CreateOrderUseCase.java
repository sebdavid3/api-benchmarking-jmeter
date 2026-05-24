package com.benchmark.orders.application;

import com.benchmark.orders.application.dto.CreateOrderInput;
import com.benchmark.orders.application.dto.CreateOrderItemInput;
import com.benchmark.orders.application.dto.CreateOrderOutput;
import com.benchmark.orders.domain.Order;
import com.benchmark.orders.domain.OrderItem;
import com.benchmark.orders.domain.OrderRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class CreateOrderUseCase {

    private final OrderRepository repo;

    public CreateOrderUseCase(OrderRepository repo) {
        this.repo = repo;
    }

    public CreateOrderOutput execute(CreateOrderInput input) {
        if (input.customerId() == null || input.customerId().isBlank()) {
            throw new IllegalArgumentException("customerId is required");
        }
        if (input.items() == null || input.items().isEmpty()) {
            throw new IllegalArgumentException("items must not be empty");
        }

        List<OrderItem> items = new ArrayList<>();
        for (int i = 0; i < input.items().size(); i++) {
            CreateOrderItemInput item = input.items().get(i);
            if (item.productId() == null || item.productId().isBlank()) {
                throw new IllegalArgumentException("item[" + i + "].productId is required");
            }
            if (item.quantity() <= 0) {
                throw new IllegalArgumentException("item[" + i + "].quantity must be greater than 0");
            }
            if (item.price() < 0) {
                throw new IllegalArgumentException("item[" + i + "].price must be >= 0");
            }
            items.add(new OrderItem(item.productId(), item.quantity(), item.price()));
        }

        Order order = Order.create(input.customerId(), items);
        repo.save(order);

        return new CreateOrderOutput(
                order.getOrderId(),
                order.getCustomerId(),
                order.getTotalAmount(),
                order.getItemsCount(),
                order.getCreatedAt()
        );
    }
}
