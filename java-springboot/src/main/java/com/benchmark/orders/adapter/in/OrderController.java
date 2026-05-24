package com.benchmark.orders.adapter.in;

import com.benchmark.orders.application.CreateOrderUseCase;
import com.benchmark.orders.application.dto.CreateOrderInput;
import com.benchmark.orders.application.dto.CreateOrderOutput;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final CreateOrderUseCase useCase;

    public OrderController(CreateOrderUseCase useCase) {
        this.useCase = useCase;
    }

    @PostMapping
    public ResponseEntity<?> createOrder(@RequestBody CreateOrderInput input) {
        try {
            CreateOrderOutput output = useCase.execute(input);
            return ResponseEntity.ok(output);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "validation_error", "message", e.getMessage()));
        }
    }
}
