package com.benchmark.orders.adapter.out;

import com.benchmark.orders.domain.Order;
import com.benchmark.orders.domain.OrderItem;
import com.benchmark.orders.domain.OrderRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Repository
public class PostgresOrderRepository implements OrderRepository {

    private final JdbcTemplate jdbc;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'").withZone(ZoneOffset.UTC);

    public PostgresOrderRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    @Transactional
    public void save(Order order) {
        jdbc.update(
                "INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at) VALUES (?, ?, ?, ?, ?::timestamp)",
                order.getOrderId(), order.getCustomerId(), order.getTotalAmount(), order.getItemsCount(), order.getCreatedAt()
        );

        for (OrderItem item : order.getItems()) {
            jdbc.update(
                    "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)",
                    order.getOrderId(), item.getProductId(), item.getQuantity(), item.getPrice()
            );
        }
    }

    @Override
    public Order findById(String orderId) {
        List<Order> orders = jdbc.query(
                "SELECT order_id, customer_id, total_amount, items_count, created_at FROM orders WHERE order_id = ?",
                (ResultSet rs, int rowNum) -> {
                    String oid = rs.getString("order_id");
                    String customerId = rs.getString("customer_id");
                    double total = rs.getDouble("total_amount");
                    int count = rs.getInt("items_count");
                    Timestamp ts = rs.getTimestamp("created_at");
                    String createdAt = ts != null
                            ? FORMATTER.format(ts.toInstant())
                            : rs.getString("created_at");

                    List<OrderItem> items = jdbc.query(
                            "SELECT product_id, quantity, price FROM order_items WHERE order_id = ?",
                            (ResultSet rs2, int rowNum2) -> new OrderItem(
                                    rs2.getString("product_id"),
                                    rs2.getInt("quantity"),
                                    rs2.getDouble("price")
                            ),
                            oid
                    );

                    return new Order(oid, customerId, items, total, count, createdAt);
                },
                orderId
        );
        return orders.isEmpty() ? null : orders.get(0);
    }
}
