from src.infrastructure.app_factory import create_app
from src.infrastructure.config import Config

app = create_app()

if __name__ == "__main__":
    cfg = Config()
    app.run(host="0.0.0.0", port=cfg.API_PORT)
