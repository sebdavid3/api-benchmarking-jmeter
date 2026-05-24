package infrastructure

import (
	"context"
	"fmt"
	"net/http"

	"github.com/benchmark/orders/internal/adapter/in"
	"github.com/benchmark/orders/internal/adapter/out"
	"github.com/benchmark/orders/internal/application"
	"github.com/jackc/pgx/v5/pgxpool"
)

func NewServer(cfg *Config) (http.Handler, *pgxpool.Pool, error) {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable&pool_max_conns=20",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName,
	)

	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	if err := pool.Ping(context.Background()); err != nil {
		pool.Close()
		return nil, nil, fmt.Errorf("failed to ping database: %w", err)
	}

	orderRepo := out.NewPostgresOrderRepository(pool)
	createOrderUC := application.NewCreateOrderUseCase(orderRepo)
	orderHandler := in.NewOrderHandler(createOrderUC)

	mux := http.NewServeMux()
	mux.Handle("/api/orders", orderHandler)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	return mux, pool, nil
}
