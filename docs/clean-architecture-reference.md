# Plan Maestro de Implementación — Benchmarking APIs con Clean Architecture

> **Objetivo:** Construir 4 microservicios (Python/Flask, Node/NestJS, Java/Spring Boot, Go) usando Clean Architecture, evaluarlos con JMeter contra PostgreSQL y comparar su rendimiento.

---

## Tabla de Contenidos

1. [Estructura Global de Directorios](#1-estructura-global-de-directorios)
2. [Principios de Clean Architecture Aplicados](#2-principios-de-clean-architecture-aplicados)
3. [Contrato de Dominio Único](#3-contrato-de-dominio-único)
4. [Mapeo de Capas por Lenguaje](#4-mapeo-de-capas-por-lenguaje)
5. [Diseño del Endpoint POST /api/orders](#5-diseño-del-endpoint-post-apiorders)
6. [Esquema de Base de Datos (PostgreSQL)](#6-esquema-de-base-de-datos-postgresql)
7. [Estrategia de Contenerización (Docker Compose)](#7-estrategia-de-contención-docker-compose)
8. [Hoja de Ruta de Implementación por Sprints](#8-hoja-de-ruta-de-implementación-por-sprints)
9. [Automatización JMeter](#9-automatización-jmeter)
10. [Recolección de Métricas y Monitoreo](#10-recolección-de-métricas-y-monitoreo)
11. [Checklist de Verificación por Stack](#11-checklist-de-verificación-por-stack)
12. [Manual de Traducción de Dominio entre Lenguajes](#12-manual-de-traducción-de-dominio-entre-lenguajes)

---

## 1. Estructura Global de Directorios

```text
api-benchmarking-jmeter/
├── README.md
├── docs/
│   └── clean-architecture-reference.md   ← ESTE DOCUMENTO
├── shared/
│   ├── db-init/
│   │   └── 01-init.sql                    # DDL único para los 4 stacks
│   ├── docker/
│   │   └── docker-compose.db.yml          # Opcional: DB compartida (solo desarrollo)
│   └── jmeter/
│       ├── api-benchmark.jmx              # Test plan parametrizado
│       └── payload.json                   # JSON de entrada para pruebas
├── scripts/
│   ├── run-load-test.sh                   # Wrapper para lanzar JMeter por stack
│   └── monitor.sh                         # Captura docker stats a archivo
│
├── python-flask/
│   ├── src/
│   │   ├── domain/                        # Entidades + Interface Repo
│   │   │   ├── __init__.py
│   │   │   ├── order.py                   # Order, OrderItem (dataclasses)
│   │   │   └── order_repository.py        # Interfaz Abstracta
│   │   ├── application/                   # Casos de Uso + DTOs
│   │   │   ├── __init__.py
│   │   │   ├── create_order_use_case.py   # Orquestador
│   │   │   └── dto.py                     # CreateOrderInput, CreateOrderOutput
│   │   ├── adapter/
│   │   │   ├── __init__.py
│   │   │   ├── in/
│   │   │   │   └── order_controller.py    # Blueprint Flask + request/response DTOs
│   │   │   └── out/
│   │   │       └── postgres_order_repo.py # Impl. concreta con psycopg2/sqlalchemy-core
│   │   └── infrastructure/
│   │       ├── __init__.py
│   │       ├── app_factory.py             # create_app()
│   │       ├── config.py                  # Lectura de env vars
│   │       └── main.py                    # Punto de entrada
│   ├── tests/
│   │   └── test_create_order.py
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
│
├── nodejs-nestjs/
│   ├── src/
│   │   ├── domain/
│   │   │   ├── order.entity.ts
│   │   │   └── order.repository.interface.ts
│   │   ├── application/
│   │   │   ├── create-order.use-case.ts
│   │   │   └── dto.ts
│   │   ├── adapter/
│   │   │   ├── in/
│   │   │   │   └── order.controller.ts
│   │   │   └── out/
│   │   │       └── postgres-order.repository.ts
│   │   └── infrastructure/
│   │       ├── app.module.ts
│   │       ├── config.service.ts
│   │       └── main.ts
│   ├── tests/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── package.json
│   └── tsconfig.json
│
├── java-springboot/
│   ├── src/main/java/com/benchmark/orders/
│   │   ├── domain/
│   │   │   ├── Order.java
│   │   │   ├── OrderItem.java
│   │   │   └── OrderRepository.java       # Interface
│   │   ├── application/
│   │   │   ├── CreateOrderUseCase.java
│   │   │   └── dto/
│   │   │       ├── CreateOrderInput.java
│   │   │       └── CreateOrderOutput.java
│   │   ├── adapter/
│   │   │   ├── in/
│   │   │   │   └── OrderController.java   # @RestController
│   │   │   └── out/
│   │   │       └── PostgresOrderRepository.java
│   │   └── infrastructure/
│   │       ├── OrderApplication.java       # @SpringBootApplication
│   │       └── config/
│   │           └── DatabaseConfig.java
│   ├── src/main/resources/
│   │   └── application.properties
│   ├── src/test/...
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── pom.xml
│
└── go-stdlib/
    ├── internal/
    │   ├── domain/
    │   │   ├── order.go                   # Structs + Repository interface
    │   │   └── repository.go
    │   ├── application/
    │   │   ├── create_order_usecase.go
    │   │   └── dto.go
    │   ├── adapter/
    │   │   ├── in/
    │   │   │   └── order_handler.go       # http.Handler
    │   │   └── out/
    │   │       └── postgres_order_repo.go # pgx/sqlx impl
    │   └── infrastructure/
    │       ├── config.go
    │       └── server.go                  # Router setup
    ├── cmd/
    │   └── api/
    │       └── main.go                    # Entrypoint
    ├── Dockerfile
    ├── docker-compose.yml
    └── go.mod
```

---

## 2. Principios de Clean Architecture Aplicados

### 2.1 Regla de Dependencia

```
 ┌─────────────────────────────────────────┐
 │              INFRAESTRUCTURA            │  ← Conoce el framework (Flask/NestJS/Spring/net/http)
 │  ┌───────────────────────────────────┐  │
 │  │           ADAPTERS                │  │  ← Conoce dominio y aplicación
 │  │  ┌─────────────────────────────┐  │  │
 │  │  │       APPLICATION           │  │  │  ← Conoce dominio, NO frameworks
 │  │  │  ┌───────────────────────┐  │  │  │
 │  │  │  │       DOMAIN          │  │  │  │  ← NO conoce nada externo
 │  │  │  │  Entities + Interfaces│  │  │  │
 │  │  │  └───────────────────────┘  │  │  │
 │  │  └─────────────────────────────┘  │  │
 │  └───────────────────────────────────┘  │
 └─────────────────────────────────────────┘
```

### 2.2 Responsabilidades por Capa

| Capa | Responsabilidad | Qué NO debe hacer |
|---|---|---|
| **Domain** | Entidades, reglas de negocio, interfaces de repositorios | Importar frameworks, manejar HTTP, saber de SQL |
| **Application** | Orquestar casos de uso, DTOs de entrada/salida, validación de aplicación | Depender de un framework HTTP, parsear requests |
| **Adapter (In)** | Traducir HTTP → Input DTO, llamar Use Case, traducir Output DTO → HTTP Response | Contener lógica de negocio, hacer cálculos |
| **Adapter (Out)** | Implementar interfaces de repositorios (SQL, ORM, cache) | Contener reglas de negocio, exponer HTTP |
| **Infrastructure** | Configurar el framework, wires, inyección de dependencias, main/bootstrap | Ser importada por capas internas |

### 2.3 Reglas de Oro para el Taller

1. **El cálculo de `totalAmount` e `itemsCount` SIEMPRE ocurre en `Domain` o `Application`**. Jamás en el controller.
2. **El `orderId` (UUID) se genera en `Domain` o `Application`**. No en la base de datos (salvo el serial `id` que es interno).
3. **El Input DTO del Use Case NO es el JSON del request**. Hay una transformación en el adapter.
4. **La interfaz `OrderRepository` se define en `domain/`**. La implementación concreta (Postgres) vive en `adapter/out/`.
5. **Usa la menor cantidad de dependencias posible**. Ej: en Python usa `psycopg2` o `SQLAlchemy Core`, NO el ORM completo. En Go usa `pgx` o `sqlx`, NO un ORM. Esto mantiene la comparación más justa.

---

## 3. Contrato de Dominio Único

Este es el contrato que debe cumplirse IDÉNTICAMENTE en los 4 stacks. Solo cambia la sintaxis del lenguaje.

### 3.1 Entidad `OrderItem`

```
OrderItem {
    productId : String
    quantity  : Integer
    price     : Decimal

    // Comportamiento
    subtotal() : Decimal  →  quantity * price
}
```

**Restricciones:**
- `quantity` > 0
- `price` >= 0

### 3.2 Entidad `Order` (Agregado Raíz)

```
Order {
    orderId    : String (UUID v4)
    customerId : String
    items      : List<OrderItem>
    totalAmount: Decimal   // ← CALCULADO, nunca recibido del input
    itemsCount : Integer   // ← CALCULADO, nunca recibido del input
    createdAt  : DateTime (UTC)

    // Constructor / Factory
    static create(customerId: String, items: List<OrderItem>) : Order {
        orderId     = generateUUID()
        totalAmount = sum(items.map(i => i.subtotal()))
        itemsCount  = sum(items.map(i => i.quantity))
        createdAt   = nowUTC()
        return Order(orderId, customerId, items, totalAmount, itemsCount, createdAt)
    }
}
```

### 3.3 Interfaz `OrderRepository`

```
interface OrderRepository {
    save(order: Order): void              // Inserta en orders + order_items (transaccional)
    findById(orderId: String): Order?     // Opcional: no requerido para el taller pero buena práctica
}
```

### 3.4 Caso de Uso `CreateOrder`

```
Input:
    CreateOrderInput {
        customerId : String
        items      : List<{
            productId : String
            quantity  : Integer
            price     : Decimal
        }>
    }

Output:
    CreateOrderOutput {
        orderId     : String
        customerId  : String
        totalAmount : Decimal
        itemsCount  : Integer
        createdAt   : DateTime (ISO 8601 string)
    }

Flujo:
    1. Validar input (customerId no vacío, items no vacío, cantidades > 0)
    2. Mapear CreateOrderInput.items → List<OrderItem>
    3. Llamar Order.create(customerId, items) → Order
    4. Llamar orderRepository.save(order)
    5. Mapear Order → CreateOrderOutput
    6. Retornar CreateOrderOutput
```

---

## 4. Mapeo de Capas por Lenguaje

### 4.1 Python (Flask)

| Capa | Artefacto | Ubicación | Notas |
|---|---|---|---|
| Domain | `@dataclass Order`, `@dataclass OrderItem` | `domain/order.py` | Método `subtotal()` en `OrderItem`, `@staticmethod create()` en `Order` |
| Domain | `class OrderRepository(ABC)` | `domain/order_repository.py` | `@abstractmethod save(order)`, `@abstractmethod find_by_id(id)` |
| Application | `class CreateOrderUseCase` | `application/create_order_use_case.py` | Recibe `OrderRepository` en constructor. Método `execute(input: CreateOrderInput) -> CreateOrderOutput` |
| Application | `@dataclass CreateOrderInput`, `@dataclass CreateOrderOutput` | `application/dto.py` | Simples estructuras de datos |
| Adapter In | `@orders_bp.route('/api/orders', methods=['POST'])` | `adapter/in/order_controller.py` | Blueprint Flask. Parse JSON → CreateOrderInput → UseCase → Dict → jsonify |
| Adapter Out | `class PostgresOrderRepository(OrderRepository)` | `adapter/out/postgres_order_repo.py` | psycopg2 con transacciones explícitas |
| Infrastructure | `create_app()` | `infrastructure/app_factory.py` | Factory que wirea todo |
| Infrastructure | `main.py` | `infrastructure/main.py` | `app = create_app(); app.run(host='0.0.0.0', port=5001)` |

### 4.2 Node.js (NestJS)

| Capa | Artefacto | Ubicación | Notas |
|---|---|---|---|
| Domain | `class Order`, `class OrderItem` | `domain/order.entity.ts` | Clase con `static create()` y métodos |
| Domain | `interface OrderRepository` | `domain/order.repository.interface.ts` | `save(order: Order): Promise<void>` |
| Application | `@Injectable() class CreateOrderUseCase` | `application/create-order.use-case.ts` | Injecta token `'OrderRepository'` |
| Application | `class CreateOrderInput`, `class CreateOrderOutput` | `application/dto.ts` | Classes simples |
| Adapter In | `@Controller('api/orders') class OrderController` | `adapter/in/order.controller.ts` | `@Post()` con `@Body()` |
| Adapter Out | `@Injectable() class PostgresOrderRepository implements OrderRepository` | `adapter/out/postgres-order.repository.ts` | Pool pg nativo o TypeORM Repository |
| Infrastructure | `@Module()` decorators | `infrastructure/app.module.ts` | Providers array wirea interfaces a impls |
| Infrastructure | `NestFactory.create(AppModule)` | `infrastructure/main.ts` | Listen en 5002 |

### 4.3 Java (Spring Boot)

| Capa | Artefacto | Ubicación | Notas |
|---|---|---|---|
| Domain | `class Order`, `class OrderItem` | `domain/Order.java` | Clases POJO, factory method `create()` |
| Domain | `interface OrderRepository` | `domain/OrderRepository.java` | `void save(Order order)` |
| Application | `@Service class CreateOrderUseCase` | `application/CreateOrderUseCase.java` | Constructor injection de `OrderRepository` |
| Application | `record CreateOrderInput(...)`, `record CreateOrderOutput(...)` | `application/dto/` | Records de Java 17+ |
| Adapter In | `@RestController @RequestMapping("/api/orders") class OrderController` | `adapter/in/OrderController.java` | `@PostMapping` con `@RequestBody` |
| Adapter Out | `@Repository class PostgresOrderRepository implements OrderRepository` | `adapter/out/PostgresOrderRepository.java` | `JdbcTemplate` o `EntityManager` |
| Infrastructure | `@SpringBootApplication class OrderApplication` | `infrastructure/OrderApplication.java` | `SpringApplication.run()` |

### 4.4 Go (net/http + pgx)

| Capa | Artefacto | Ubicación | Notas |
|---|---|---|---|
| Domain | `type Order struct`, `type OrderItem struct` | `internal/domain/order.go` | `func NewOrder(...) Order`, `func (oi OrderItem) Subtotal() float64` |
| Domain | `type OrderRepository interface` | `internal/domain/repository.go` | `Save(ctx context.Context, order Order) error` |
| Application | `type CreateOrderUseCase struct` | `internal/application/create_order_usecase.go` | Campo `repo domain.OrderRepository`. `func (uc *CreateOrderUseCase) Execute(...)` |
| Application | `type CreateOrderInput struct`, `type CreateOrderOutput struct` | `internal/application/dto.go` | Structs con tags `json` |
| Adapter In | `func (h *OrderHandler) ServeHTTP(...)` | `internal/adapter/in/order_handler.go` | `http.Handler` interface |
| Adapter Out | `type PostgresOrderRepository struct` | `internal/adapter/out/postgres_order_repo.go` | `*pgxpool.Pool` |
| Infrastructure | `func NewServer(...) http.Handler` | `internal/infrastructure/server.go` | Wirea y retorna `http.ServeMux` |
| Cmd | `func main()` | `cmd/api/main.go` | Lee config, crea server, `http.ListenAndServe(":5004", ...)` |

---

## 5. Diseño del Endpoint POST /api/orders

### 5.1 Request

```http
POST /api/orders HTTP/1.1
Host: localhost:{PORT}
Content-Type: application/json

{
  "customerId": "C123",
  "items": [
    { "productId": "P1", "quantity": 2, "price": 10.5 },
    { "productId": "P2", "quantity": 1, "price": 5.0 }
  ]
}
```

### 5.2 Response (200 OK)

```json
{
  "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "customerId": "C123",
  "totalAmount": 26.00,
  "itemsCount": 3,
  "createdAt": "2026-05-24T12:34:56Z"
}
```

### 5.3 Response (400 Bad Request) — si la validación falla

```json
{
  "error": "validation_error",
  "message": "customerId is required",
  "details": null
}
```

### 5.4 Flujo de Procesamiento (Secuencia)

```
[Cliente HTTP/JMeter]
        │  POST /api/orders { JSON body }
        ▼
[Adapter/In: Controller]
        │  Parse JSON → CreateOrderInput
        ▼
[Application: CreateOrderUseCase]
        │  1. Validar input
        │  2. Crear OrderItem entities
        │  3. Order.create(customerId, items)
        │  4. repo.save(order)
        │  5. Mapear → CreateOrderOutput
        ▼
[Adapter/Out: PostgresOrderRepository]
        │  BEGIN TRANSACTION
        │  INSERT INTO orders (...)
        │  INSERT INTO order_items (...) x N
        │  COMMIT
        ▼
[Controller]
        │  Mapear CreateOrderOutput → JSON Response
        ▼
[Cliente: 200 OK { json response }]
```

---

## 6. Esquema de Base de Datos (PostgreSQL)

### 6.1 Script DDL Definitivo

Archivo: `shared/db-init/01-init.sql`

```sql
-- ============================================================
-- Benchmark: API de Órdenes — Esquema de Base de Datos
-- Versión: 1.0
-- Uso: Montado como volumen en /docker-entrypoint-initdb.d/
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS orders (
    id            SERIAL       PRIMARY KEY,
    order_id      VARCHAR(50)  UNIQUE NOT NULL,
    customer_id   VARCHAR(50)  NOT NULL,
    total_amount  NUMERIC(10,2) NOT NULL,
    items_count   INT          NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id            SERIAL       PRIMARY KEY,
    order_id      VARCHAR(50)  NOT NULL,
    product_id    VARCHAR(50)  NOT NULL,
    quantity      INT          NOT NULL,
    price         NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_order_items_order_id
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_orders_order_id
    ON orders(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items(order_id);

COMMIT;
```

### 6.2 Conexión desde la Aplicación

Variables de entorno que deben usar los 4 stacks (idénticas):

```env
DB_HOST=db          # Nombre del contenedor en docker-compose
DB_PORT=5432        # Puerto interno del contenedor
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=orders_db
```

### 6.3 Notas de Implementación del Repositorio

- **Transaccionalidad**: `INSERT INTO orders` + `INSERT INTO order_items` deben ejecutarse en la misma transacción.
- **Retry simple**: Si la API recibe alta concurrencia, considera un retry en caso de deadlock (especialmente en Go y Python donde la gestión de concurrencia es manual).
- **Connection Pool**: Usa un pool de conexiones, NO una conexión por request.
  - Python: `psycopg2.pool.ThreadedConnectionPool` (min=5, max=20)
  - Node: `pg.Pool` (max: 20)
  - Java: HikariCP (viene con Spring Boot, configurar `maximumPoolSize=20`)
  - Go: `pgxpool` (max_conns=20)

---

## 7. Estrategia de Contención (Docker Compose)

### 7.1 Principio: Aislamiento Total

Cada stack tiene su propia instancia de PostgreSQL para garantizar que las pruebas de carga no se contaminen entre stacks.

### 7.2 Asignación de Puertos y Recursos

| Stack | Puerto API (host) | Puerto DB (host) | Contenedor API | Contenedor DB | Red Docker | Volumen DB |
|---|---|---|---|---|---|---|
| Python + Flask | `5001` | `5433` | `api-python` | `db-python` | `python-net` | `pgdata_python` |
| Node.js + NestJS | `5002` | `5434` | `api-nodejs` | `db-nodejs` | `nodejs-net` | `pgdata_nodejs` |
| Java + Spring Boot | `5003` | `5435` | `api-java` | `db-java` | `java-net` | `pgdata_java` |
| Go (stdlib) | `5004` | `5436` | `api-go` | `db-go` | `go-net` | `pgdata_go` |

### 7.3 Plantilla de docker-compose.yml (Go — referencia)

```yaml
version: "3.9"
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: api-go
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_USER=postgres
      - DB_PASSWORD=postgres
      - DB_NAME=orders_db
    ports:
      - "5004:5004"          # ← Único por stack
    depends_on:
      db:
        condition: service_healthy
    networks:
      - go-net
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    container_name: db-go
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=orders_db
    ports:
      - "5436:5432"          # ← Único por stack
    volumes:
      - pgdata_go:/var/lib/postgresql/data
      - ../shared/db-init:/docker-entrypoint-initdb.d:ro
    networks:
      - go-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d orders_db"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata_go:

networks:
  go-net:
    driver: bridge
```

### 7.4 Variaciones por Stack

Los otros stacks usan exactamente la misma plantilla, cambiando solo:

1. **Python** → Puerto API `5001`, Puerto DB host `5433`, volumen `pgdata_python`, red `python-net`, contenedores `api-python` / `db-python`
2. **Node.js** → Puerto API `5002`, Puerto DB host `5434`, volumen `pgdata_nodejs`, red `nodejs-net`, contenedores `api-nodejs` / `db-nodejs`
3. **Java** → Puerto API `5003`, Puerto DB host `5435`, volumen `pgdata_java`, red `java-net`, contenedores `api-java` / `db-java`

### 7.5 Dockerfile Mínimo por Stack

**Python:**
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
EXPOSE 5001
CMD ["python", "-m", "src.infrastructure.main"]
```

**Node (NestJS):**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist/ ./dist/
EXPOSE 5002
CMD ["node", "dist/infrastructure/main.js"]
```

**Java (Spring Boot):**
```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/orders-api-*.jar app.jar
EXPOSE 5003
CMD ["java", "-jar", "app.jar"]
```

**Go:**
```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o api ./cmd/api/

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/api .
EXPOSE 5004
CMD ["./api"]
```

---

## 8. Hoja de Ruta de Implementación por Sprints

### Fase 1: Infraestructura Base (Día 1)

**Objetivo:** Todo listo para copiar-pegar lógica de dominio entre stacks.

| Paso | Tarea | Archivos | Verificación |
|---|---|---|---|
| 1.1 | Crear estructura de directorios global | Todos los directorios del layout en sección 1 | `tree -L 3` muestra la estructura |
| 1.2 | Escribir DDL de base de datos | `shared/db-init/01-init.sql` | Ejecutar manualmente en un psql local o vía Docker |
| 1.3 | Escribir payload de pruebas | `shared/jmeter/payload.json` | `curl -X POST localhost:5004/api/orders -d @payload.json` (cuando Go esté listo) |
| 1.4 | Crear scripts de monitoreo y ejecución | `scripts/monitor.sh`, `scripts/run-load-test.sh` | Dar permisos de ejecución `chmod +x` |
| 1.5 | Crear JMeter base parametrizado | `shared/jmeter/api-benchmark.jmx` | Abrir en JMeter GUI y ejecutar un test dummy |
| 1.6 | Configurar Git con `.gitignore` | `.gitignore` global | Que no trackee `node_modules`, `__pycache__`, `target/`, `*.jar`, `dbdata/` |

### Fase 2: Desarrollo de los 4 Stacks (Días 2-5)

#### Orden Estratégico

```
Go ──→ Python ──→ Node.js/NestJS ──→ Java/Spring Boot
(1°)    (2°)       (3°)               (4°)
```

**Fundamento:** Go es el más simple (sin ORM, sin DI compleja). Define la lógica de referencia. Python es expresivo y copiable. NestJS requiere modularización pero es TypeScript. Spring Boot tiene el mayor boilerplate; hazlo al final cuando la lógica esté cristalizada.

#### Día 2: Go (net/http + pgx)

| Paso | Tarea | Output Esperado |
|---|---|---|
| 2.1 | `go mod init github.com/benchmark/orders` | `go.mod` |
| 2.2 | Agregar dependencia `github.com/jackc/pgx/v5` | `go.sum` |
| 2.3 | Implementar `internal/domain/order.go` y `repository.go` | Structs, interfaz, factory |
| 2.4 | Implementar `internal/application/dto.go` y `create_order_usecase.go` | Caso de uso |
| 2.5 | Implementar `internal/adapter/out/postgres_order_repo.go` | Repo con pgxpool |
| 2.6 | Implementar `internal/adapter/in/order_handler.go` | Handler HTTP |
| 2.7 | Implementar `internal/infrastructure/server.go` y `config.go` | Router y configuración |
| 2.8 | Implementar `cmd/api/main.go` | Entrypoint |
| 2.9 | Escribir `Dockerfile` (multi-stage) | Imagen < 30 MB |
| 2.10 | Escribir `docker-compose.yml` | Puerto 5004, DB en 5436 |
| 2.11 | Probar con curl: `curl -X POST localhost:5004/api/orders -d @../shared/jmeter/payload.json -H 'Content-Type: application/json'` | Respuesta 200 con JSON |

**Template de código Go (Domain):**

```go
// internal/domain/order.go
package domain

import (
    "time"
    "github.com/google/uuid"
)

type OrderItem struct {
    ProductID string
    Quantity  int
    Price     float64
}

func (oi OrderItem) Subtotal() float64 {
    return float64(oi.Quantity) * oi.Price
}

type Order struct {
    OrderID     string
    CustomerID  string
    Items       []OrderItem
    TotalAmount float64
    ItemsCount  int
    CreatedAt   time.Time
}

func NewOrder(customerID string, items []OrderItem) Order {
    var total float64
    var count int
    for _, item := range items {
        total += item.Subtotal()
        count += item.Quantity
    }
    return Order{
        OrderID:     uuid.New().String(),
        CustomerID:  customerID,
        Items:       items,
        TotalAmount: total,
        ItemsCount:  count,
        CreatedAt:   time.Now().UTC(),
    }
}
```

#### Día 3: Python + Flask

| Paso | Tarea | Output Esperado |
|---|---|---|
| 3.1 | Crear `requirements.txt` (`flask, psycopg2-binary, python-dotenv`) | Dependencias definidas |
| 3.2 | Implementar `domain/order.py` (dataclasses + factory) | Igual lógica que Go |
| 3.3 | Implementar `domain/order_repository.py` (ABC) | Interfaz abstracta |
| 3.4 | Implementar `application/dto.py` y `create_order_use_case.py` | Caso de uso |
| 3.5 | Implementar `adapter/out/postgres_order_repo.py` | Pool psycopg2 + transacciones |
| 3.6 | Implementar `adapter/in/order_controller.py` | Blueprint Flask |
| 3.7 | Implementar `infrastructure/app_factory.py` | Factory que wirea dependencias |
| 3.8 | Implementar `infrastructure/main.py` | `app.run(port=5001)` |
| 3.9 | Escribir `Dockerfile` y `docker-compose.yml` | Puerto 5001, DB en 5433 |
| 3.10 | Probar con curl puerto 5001 | 200 OK |

#### Día 4: Node.js + NestJS

| Paso | Tarea | Output Esperado |
|---|---|---|
| 4.1 | `nest new orders-api` (o config manual) | Proyecto NestJS base |
| 4.2 | Instalar `@nestjs/config`, `pg` | Dependencias |
| 4.3 | Implementar `domain/order.entity.ts` y `order.repository.interface.ts` | Clase + Interfaz |
| 4.4 | Implementar `application/dto.ts` y `create-order.use-case.ts` | Servicio inyectable |
| 4.5 | Implementar `adapter/out/postgres-order.repository.ts` | Pool pg nativo |
| 4.6 | Implementar `adapter/in/order.controller.ts` | `@Controller('api/orders')` |
| 4.7 | Configurar `infrastructure/app.module.ts` (proveedores) | Módulo que wirea |
| 4.8 | Implementar `infrastructure/main.ts` | Listen en 5002 |
| 4.9 | Escribir `Dockerfile` y `docker-compose.yml` | Puerto 5002, DB en 5434 |
| 4.10 | `npm run build && docker compose up -d && curl` | 200 OK |

#### Día 5: Java + Spring Boot

| Paso | Tarea | Output Esperado |
|---|---|---|
| 5.1 | Generar proyecto Spring Boot (Spring Initializr: Web, JDBC, PostgreSQL) | `pom.xml` con dependencias |
| 5.2 | Implementar `domain/Order.java` y `OrderItem.java` | Clases POJO con factory |
| 5.3 | Implementar `domain/OrderRepository.java` | Interface |
| 5.4 | Implementar `application/dto/CreateOrderInput.java`, `CreateOrderOutput.java` | Records |
| 5.5 | Implementar `application/CreateOrderUseCase.java` | `@Service` |
| 5.6 | Implementar `adapter/out/PostgresOrderRepository.java` | `JdbcTemplate` |
| 5.7 | Implementar `adapter/in/OrderController.java` | `@RestController` |
| 5.8 | Implementar `infrastructure/OrderApplication.java` | Main class |
| 5.9 | Configurar `application.properties` | DB host, pool size |
| 5.10 | `mvn package -DskipTests && docker compose up -d && curl` | 200 OK |

---

### Fase 3: Automatización de Pruebas de Carga (JMeter) — Día 6

#### 8.1 Configuración del Test Plan

**Estructura del `.jmx`:**

```
Test Plan
├── User Defined Variables
│   ├── apiHost = localhost
│   ├── apiPort = ${__P(apiPort,5001)}     ← PARAMETRIZADO
│   └── apiPath = /api/orders
│
├── Thread Group: Baja Carga
│   ├── Number of Threads = 10
│   ├── Ramp-Up Period = 2
│   ├── Duration = 60 seconds
│   └── Loop Count = Forever
│       └── HTTP Request POST
│           ├── Server: ${apiHost}
│           ├── Port: ${apiPort}
│           ├── Path: ${apiPath}
│           └── Body Data: (contenido de payload.json)
│
├── Thread Group: Media Carga
│   ├── Number of Threads = 50
│   ├── Ramp-Up Period = 5
│   ├── Duration = 120 seconds
│   └── (mismo sampler)
│
├── Thread Group: Alta Carga
│   ├── Number of Threads = 100
│   ├── Ramp-Up Period = 10
│   ├── Duration = 180 seconds
│   └── (mismo sampler)
│
├── HTTP Header Manager (global)
│   └── Content-Type: application/json
│
├── HTTP Request Defaults (global)
│   ├── Server: ${apiHost}
│   ├── Port: ${apiPort}
│   └── Path: ${apiPath}
│
├── Listener: Summary Report
│   └── Write results to file: results/${__P(stackName,unknown)}-${__P(scenario,unknown)}-summary.csv
│
└── Listener: Aggregate Report
    └── Write results to file: results/${__P(stackName,unknown)}-${__P(scenario,unknown)}-aggregate.csv
```

#### 8.2 Ejecución desde Terminal

```bash
# Formato general
jmeter -n -t shared/jmeter/api-benchmark.jmx \
  -JapiPort={PUERTO} \
  -JstackName={STACK} \
  -Jscenario={ESCENARIO} \
  -l results/{STACK}-{ESCENARIO}.csv \
  -e -o results/{STACK}-{ESCENARIO}-report

# Ejemplo: Python, escenario baja carga
jmeter -n -t shared/jmeter/api-benchmark.jmx \
  -JapiPort=5001 \
  -JstackName=python \
  -Jscenario=low \
  -l results/python-low.csv \
  -e -o results/python-low-report

# Ejemplo: Go, escenario alta carga
jmeter -n -t shared/jmeter/api-benchmark.jmx \
  -JapiPort=5004 \
  -JstackName=go \
  -Jscenario=high \
  -l results/go-high.csv \
  -e -o results/go-high-report
```

#### 8.3 Script Wrapper: `scripts/run-load-test.sh`

```bash
#!/bin/bash
set -euo pipefail

STACK="${1:?USO: $0 <stack> <port> <scenario>}"
PORT="${2:?Falta puerto}"
SCENARIO="${3:?Falta escenario (low|medium|high)}"

JMX="shared/jmeter/api-benchmark.jmx"
RESULTS_DIR="results"
mkdir -p "${RESULTS_DIR}"

jmeter -n \
  -t "${JMX}" \
  -JapiPort="${PORT}" \
  -JstackName="${STACK}" \
  -Jscenario="${SCENARIO}" \
  -l "${RESULTS_DIR}/${STACK}-${SCENARIO}.csv" \
  -e -o "${RESULTS_DIR}/${STACK}-${SCENARIO}-report"

echo "Resultados en: ${RESULTS_DIR}/${STACK}-${SCENARIO}.csv"
echo "Reporte HTML en: ${RESULTS_DIR}/${STACK}-${SCENARIO}-report/index.html"
```

---

### Fase 4: Recolección de Métricas y Monitoreo — Día 7

#### 9.1 Script de Monitoreo: `scripts/monitor.sh`

```bash
#!/bin/bash
set -euo pipefail

STACK="${1:?USO: $0 <stack> <scenario>}"
SCENARIO="${2:?Falta escenario (low|medium|high)}"

RESULTS_DIR="results"
mkdir -p "${RESULTS_DIR}"

OUT="${RESULTS_DIR}/metrics-${STACK}-${SCENARIO}.csv"

# Cabecera CSV
echo "timestamp,container,cpu_percent,mem_usage,mem_percent" > "${OUT}"

# Bucle de captura cada 2 segundos
while true; do
    docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" >> "${OUT}"
    sleep 2
done
```

**Uso:**
```bash
# Terminal 1: Iniciar monitoreo en background
./scripts/monitor.sh go high &
MONITOR_PID=$!

# Terminal 2: Ejecutar la prueba JMeter
./scripts/run-load-test.sh go 5004 high

# Terminal 1: Detener monitoreo al finalizar
kill $MONITOR_PID

# Ver resultados
cat results/metrics-go-high.csv
```

#### 9.2 Procedimiento Completo de Test por Stack y Escenario

```
PASO 1: Levantar el stack
   cd go-stdlib && docker compose up -d && cd ..
   Esperar 10s a que la DB esté healthy

PASO 2: Verificar que responde
   curl -s -X POST http://localhost:5004/api/orders \
     -H 'Content-Type: application/json' \
     -d @shared/jmeter/payload.json | jq .

PASO 3: Iniciar monitoreo en background
   ./scripts/monitor.sh go high &
   MONITOR_PID=$!

PASO 4: Abrir htop en otra terminal (para screenshots)
   htop

PASO 5: Ejecutar prueba de carga
   ./scripts/run-load-test.sh go 5004 high

PASO 6: Detener monitoreo
   kill $MONITOR_PID

PASO 7: Tomar screenshots
   - JMeter Aggregate Report
   - JMeter Summary Report
   - htop durante la carga
   - docker stats snapshot

PASO 8: Registrar métricas en la tabla
   Extraer de results/go-high.csv y metrics-go-high.csv

PASO 9: Bajar el stack
   cd go-stdlib && docker compose down -v && cd ..
```

#### 9.3 Tabla de Métricas a Completar

**Para cada stack y escenario, registrar:**

| Métrica | Fuente | Cómo Extraerla |
|---|---|---|
| Avg Response Time (ms) | JMeter Summary CSV | Columna `average` |
| P95 Response Time (ms) | JMeter Aggregate CSV | Columna `pct95` |
| Throughput (req/s) | JMeter Summary CSV | Columna `throughput` |
| % Error | JMeter Summary CSV | Columna `error%` |
| CPU API (%) | `metrics-*.csv` | Promedio de `cpu_percent` del contenedor `api-*` |
| RAM API (MiB) | `metrics-*.csv` | Último valor de `mem_usage` del contenedor `api-*` |
| CPU DB (%) | `metrics-*.csv` | Promedio de `cpu_percent` del contenedor `db-*` |
| RAM DB (MiB) | `metrics-*.csv` | Último valor de `mem_usage` del contenedor `db-*` |
| Observaciones | Manual | Timeouts, GC pauses, errores, caídas |

#### 9.4 Plantilla de Tabla Comparativa (Entrega Grupal)

**Consumo del Sistema:**
```
| Escenario   | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones    |
|-------------|-------------|----------------|------------|---------------|-------------------|
| Baja (10)   | 12%         | 90             | 5%         | 70            | Estable           |
| Media (50)  | 55%         | 180            | 18%        | 100           | Sin errores       |
| Alta (100)  | 92%         | 350            | 30%        | 150           | Latencias altas   |
```

**Comparación de Desempeño:**
```
| Stack       | Avg (ms) | P95 (ms) | Throughput (req/s) | % Error |
|-------------|----------|----------|---------------------|---------|
| Flask       | 260      | 380      | 210                 | 5%      |
| NestJS      | 180      | 290      | 320                 | 3%      |
| Spring Boot | 55       | 80       | 700                 | 1%      |
| Go          | 25       | 40       | 900                 | 0%      |
```

---

## 10. Checklist de Verificación por Stack

Antes de pasar al siguiente stack, verifica que el actual cumple con:

- [ ] `curl POST /api/orders` retorna `200` con `{ "orderId", "customerId", "totalAmount", "itemsCount", "createdAt" }`
- [ ] El `totalAmount` es igual a `Σ (quantity × price)` de los items del input
- [ ] El `itemsCount` es igual a `Σ quantity` de los items del input
- [ ] Existe una fila en la tabla `orders` con los mismos datos
- [ ] Existen N filas en `order_items` (una por item del pedido)
- [ ] `totalAmount` NO se recibe en el JSON de entrada (se calcula internamente)
- [ ] El `orderId` es un UUID válido
- [ ] `docker compose up -d` levanta ambos contenedores
- [ ] `docker compose down` los detiene
- [ ] La aplicación NO loggea la petición a stdout durante el benchmark (evitar I/O costoso)
- [ ] El connection pool está limitado a 20 conexiones máximo

---

## 11. Manual de Traducción de Dominio entre Lenguajes

Esta sección te permite copiar la lógica de dominio de un lenguaje a otro rápidamente.

### 11.1 Creación de Order (Factory)

| Lenguaje | Código |
|---|---|
| **Go** | `order := domain.NewOrder(customerID, items)` |
| **Python** | `order = Order.create(customer_id, items)` |
| **TypeScript** | `const order = Order.create(customerId, items);` |
| **Java** | `Order order = Order.create(customerId, items);` |

### 11.2 Subtotal de OrderItem

| Lenguaje | Código |
|---|---|
| **Go** | `oi.Subtotal()` → `float64(oi.Quantity) * oi.Price` |
| **Python** | `oi.subtotal()` → `self.quantity * self.price` |
| **TypeScript** | `oi.subtotal()` → `this.quantity * this.price` |
| **Java** | `oi.subtotal()` → `this.quantity * this.price` |

### 11.3 Generación de UUID

| Lenguaje | Librería/API |
|---|---|
| **Go** | `github.com/google/uuid` → `uuid.New().String()` |
| **Python** | `import uuid` → `str(uuid.uuid4())` |
| **TypeScript** | `import { v4 as uuidv4 } from 'uuid'` → `uuidv4()` |
| **Java** | `java.util.UUID` → `UUID.randomUUID().toString()` |

### 11.4 Inserción Transaccional

| Lenguaje | Patrón |
|---|---|
| **Go** | `tx, _ := pool.Begin(ctx); tx.Exec(...); tx.Commit(ctx)` |
| **Python** | `conn = pool.getconn(); conn.autocommit = False; cur.execute(...); conn.commit()` |
| **TypeScript** | `const client = await pool.connect(); await client.query('BEGIN'); await client.query(...); await client.query('COMMIT')` |
| **Java** | `@Transactional` en el método save, JdbcTemplate `batchUpdate` o `update` |

### 11.5 Validación del Input

Antes de crear `Order`, el UseCase debe validar:

```pseudocode
validate(input):
    assert input.customerId is not null/empty
    assert input.items is not null/empty
    for each item in items:
        assert item.productId is not empty
        assert item.quantity > 0
        assert item.price >= 0
```

**En cada lenguaje:**

| Lenguaje | Implementación |
|---|---|
| **Go** | `if input.CustomerID == "" { return error }` (manual, sin framework) |
| **Python** | `if not input.customer_id: raise ValueError(...)` |
| **TypeScript** | `if (!input.customerId) throw new BadRequestException(...)` |
| **Java** | `if (input.customerId() == null || input.customerId().isBlank()) throw new IllegalArgumentException(...)` |

---

## Fin del Documento

Este documento es la fuente de verdad para los 4 stacks. Ante cualquier duda durante la implementación, vuelve a esta referencia.

**Filepath:** `docs/clean-architecture-reference.md`
