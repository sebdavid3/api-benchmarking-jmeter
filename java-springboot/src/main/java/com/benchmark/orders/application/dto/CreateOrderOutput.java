package com.benchmark.orders.application.dto;

public record CreateOrderOutput(
    String orderId,
    String customerId,
    double totalAmount,
    int itemsCount,
    String createdAt
) {}
