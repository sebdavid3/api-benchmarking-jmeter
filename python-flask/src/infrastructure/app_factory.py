import importlib
import logging
import time

from flask import Flask
from psycopg2.pool import ThreadedConnectionPool

from src.adapter.out.postgres_order_repo import PostgresOrderRepository
from src.application.create_order_use_case import CreateOrderUseCase
from src.infrastructure.config import Config


def create_app() -> Flask:
    app = Flask(__name__)

    log = logging.getLogger("werkzeug")
    log.setLevel(logging.WARNING)

    cfg = Config()

    pool = ThreadedConnectionPool(
        minconn=5,
        maxconn=20,
        host=cfg.DB_HOST,
        port=cfg.DB_PORT,
        user=cfg.DB_USER,
        password=cfg.DB_PASSWORD,
        dbname=cfg.DB_NAME,
    )

    repo = PostgresOrderRepository(pool)
    use_case = CreateOrderUseCase(repo)

    # importlib workaround: 'in' is a Python keyword, so we cannot use
    # 'from src.adapter.in.order_controller import ...' syntax.
    order_controller_mod = importlib.import_module("src.adapter.in.order_controller")
    create_order_controller = order_controller_mod.create_order_controller

    orders_bp = create_order_controller(use_case)

    app.register_blueprint(orders_bp)

    @app.route("/health")
    def health():
        return "OK"

    return app
