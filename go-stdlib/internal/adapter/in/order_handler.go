package in

import (
	"encoding/json"
	"net/http"

	"github.com/benchmark/orders/internal/application"
)

type OrderHandler struct {
	useCase *application.CreateOrderUseCase
}

func NewOrderHandler(useCase *application.CreateOrderUseCase) *OrderHandler {
	return &OrderHandler{useCase: useCase}
}

func (h *OrderHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "only POST is allowed")
		return
	}

	if r.Header.Get("Content-Type") != "application/json" {
		writeError(w, http.StatusBadRequest, "invalid_content_type", "Content-Type must be application/json")
		return
	}

	var input application.CreateOrderInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_json", "failed to parse request body")
		return
	}

	output, err := h.useCase.Execute(r.Context(), input)
	if err != nil {
		writeError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(output)
}

func writeError(w http.ResponseWriter, status int, errCode string, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{
		"error":   errCode,
		"message": message,
	})
}
