from flask import Blueprint, request, jsonify

from src.application.create_order_use_case import CreateOrderUseCase
from src.application.dto import CreateOrderInput, CreateOrderItemInput

orders_bp = Blueprint("orders", __name__)


def create_order_controller(use_case: CreateOrderUseCase) -> Blueprint:
    @orders_bp.route("/api/orders", methods=["POST"])
    def create_order():
        if not request.is_json:
            return jsonify({
                "error": "invalid_content_type",
                "message": "Content-Type must be application/json",
            }), 400

        data = request.get_json(silent=True)
        if data is None:
            return jsonify({
                "error": "invalid_json",
                "message": "failed to parse request body",
            }), 400

        try:
            items = [
                CreateOrderItemInput(
                    productId=item["productId"],
                    quantity=item["quantity"],
                    price=item["price"],
                )
                for item in data.get("items", [])
            ]
            input_dto = CreateOrderInput(
                customerId=data.get("customerId", ""),
                items=items,
            )
        except KeyError as e:
            return jsonify({
                "error": "validation_error",
                "message": f"missing required field: {e}",
            }), 400
        except TypeError:
            return jsonify({
                "error": "invalid_json",
                "message": "invalid request body format",
            }), 400

        try:
            output = use_case.execute(input_dto)
        except ValueError as e:
            return jsonify({
                "error": "validation_error",
                "message": str(e),
            }), 400

        return jsonify({
            "orderId": output.orderId,
            "customerId": output.customerId,
            "totalAmount": output.totalAmount,
            "itemsCount": output.itemsCount,
            "createdAt": output.createdAt,
        }), 200

    return orders_bp
