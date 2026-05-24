package com.benchmark.orders.domain;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

public class Order {
    private final String orderId;
    private final String customerId;
    private final List<OrderItem> items;
    private final double totalAmount;
    private final int itemsCount;
    private final String createdAt;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'").withZone(ZoneOffset.UTC);

    public Order(String orderId, String customerId, List<OrderItem> items,
                 double totalAmount, int itemsCount, String createdAt) {
        this.orderId = orderId;
        this.customerId = customerId;
        this.items = items;
        this.totalAmount = totalAmount;
        this.itemsCount = itemsCount;
        this.createdAt = createdAt;
    }

    public static Order create(String customerId, List<OrderItem> items) {
        double totalAmount = items.stream().mapToDouble(OrderItem::subtotal).sum();
        int itemsCount = items.stream().mapToInt(OrderItem::getQuantity).sum();
        String orderId = UUID.randomUUID().toString();
        String createdAt = FORMATTER.format(Instant.now());

        return new Order(orderId, customerId, items, totalAmount, itemsCount, createdAt);
    }

    public String getOrderId() { return orderId; }
    public String getCustomerId() { return customerId; }
    public List<OrderItem> getItems() { return items; }
    public double getTotalAmount() { return totalAmount; }
    public int getItemsCount() { return itemsCount; }
    public String getCreatedAt() { return createdAt; }
}
