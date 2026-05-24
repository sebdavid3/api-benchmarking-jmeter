package com.benchmark.orders.application.dto;

import java.util.List;

public record CreateOrderInput(String customerId, List<CreateOrderItemInput> items) {}
