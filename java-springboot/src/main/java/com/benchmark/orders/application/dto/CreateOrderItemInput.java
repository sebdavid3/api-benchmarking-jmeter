package com.benchmark.orders.application.dto;

public record CreateOrderItemInput(String productId, int quantity, double price) {}
