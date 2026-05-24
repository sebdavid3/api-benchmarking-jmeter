package com.benchmark.orders.domain;

public class OrderItem {
    private final String productId;
    private final int quantity;
    private final double price;

    public OrderItem(String productId, int quantity, double price) {
        this.productId = productId;
        this.quantity = quantity;
        this.price = price;
    }

    public double subtotal() {
        return this.quantity * this.price;
    }

    public String getProductId() { return productId; }
    public int getQuantity() { return quantity; }
    public double getPrice() { return price; }
}
