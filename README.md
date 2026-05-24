# API Benchmarking with PostgreSQL — Clean Architecture

> Proyecto comparativo de 4 stacks tecnológicos (Go, Python/Flask, Node.js/NestJS, Java/Spring Boot) usando Clean Architecture, evaluados con JMeter contra PostgreSQL.

## Stacks implementados

| Stack | Puerto API | Puerto DB | Driver SQL | Pool max |
|-------|-----------|-----------|------------|----------|
| **Go** (net/http + pgx) | `5004` | `5436` | pgxpool | 20 |
| **Python** (Flask + psycopg2) | `5001` | `5433` | ThreadedConnectionPool | 20 |
| **Node.js** (NestJS + pg) | `5002` | `5434` | pg.Pool | 20 |
| **Java** (Spring Boot + JdbcTemplate) | `5003` | `5435` | HikariCP | 20 |

## Arquitectura — Clean Architecture

Cada stack sigue la misma estructura de capas:

```
Domain ──► Application ──► Adapter(In/Out) ──► Infrastructure
   │            │                │                  │
   │            │                │                  │
Entidades   Casos de Uso   Controller / Repo    Config / Main
Reglas      DTOs           HTTP / SQL          Wiring / DI
```

**Reglas estrictas aplicadas:**
- `Domain` **NO** importa frameworks, HTTP, ni SQL.
- La lógica de negocio (`totalAmount`, `itemsCount`, UUID) vive en `Domain`/`Application`.
- Los controllers solo parsean requests, llaman use cases y formatean responses.
- La interfaz `OrderRepository` se define en `Domain`; la implementación PostgreSQL vive en `Adapter/Out`.
- **Sin ORMs**: Hibernate, TypeORM, SQLAlchemy ORM, GORM están prohibidos. Se usa SQL raw a través del driver nativo del lenguaje.

## Endpoint

### `POST /api/orders`

**Request body:**
```json
{
  "customerId": "C123",
  "items": [
    { "productId": "P1", "quantity": 2, "price": 10.5 },
    { "productId": "P2", "quantity": 1, "price": 5.0 }
  ]
}
```

**Response (200 OK):**
```json
{
  "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "customerId": "C123",
  "totalAmount": 26.0,
  "itemsCount": 3,
  "createdAt": "2026-05-24T12:34:56Z"
}
```

**Validación (400 Bad Request):**
- `customerId` vacío → `"customerId is required"`
- `items` vacío → `"items must not be empty"`
- `quantity <= 0` → `"quantity must be greater than 0"`
- `price < 0` → `"price must be >= 0"`

> `totalAmount` e `itemsCount` se **calculan internamente** y nunca se reciben del input.

## Esquema de Base de Datos

PostgreSQL 16, inicializado desde `shared/db-init/01-init.sql`:

```sql
CREATE TABLE orders (
    id            SERIAL         PRIMARY KEY,
    order_id      VARCHAR(50)    UNIQUE NOT NULL,
    customer_id   VARCHAR(50)    NOT NULL,
    total_amount  NUMERIC(10,2)  NOT NULL,
    items_count   INT            NOT NULL,
    created_at    TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
    id            SERIAL         PRIMARY KEY,
    order_id      VARCHAR(50)    NOT NULL,
    product_id    VARCHAR(50)    NOT NULL,
    quantity      INT            NOT NULL,
    price         NUMERIC(10,2)  NOT NULL
);
```

Cada stack tiene su **propio contenedor PostgreSQL** (aislamiento total para benchmarking justo).

## Cómo levantar un stack

```bash
cd go-stdlib      # o python-flask / nodejs-nestjs / java-springboot
docker compose up -d --build
```

Verificar con curl:
```bash
curl -X POST http://localhost:5004/api/orders \
  -H 'Content-Type: application/json' \
  -d @shared/jmeter/payload.json
```

Bajar el stack:
```bash
docker compose down
```

## Benchmarking con JMeter

Requisitos: tener JMeter instalado (`JMETER_HOME` por defecto `/opt/apache-jmeter`).

```bash
# Baja carga   (10 usuarios,  60s)
./scripts/run-load-test.sh go    5004 low
./scripts/run-load-test.sh python 5001 low
./scripts/run-load-test.sh nodejs 5002 low
./scripts/run-load-test.sh java   5003 low

# Media carga  (50 usuarios, 120s)
./scripts/run-load-test.sh go    5004 medium

# Alta carga   (100 usuarios, 180s)
./scripts/run-load-test.sh go    5004 high

# Estrés       (150 usuarios, 240s)
./scripts/run-load-test.sh go    5004 stress
```

Resultados quedan en `results/`:
- `results/<stack>-<scenario>.csv` — datos crudos
- `results/<stack>-<scenario>-report/index.html` — reporte HTML

### Monitoreo de recursos (Docker Stats)

```bash
# En terminal separada, mientras corre JMeter:
./scripts/monitor.sh go high
# Ctrl+C al terminar la prueba
```

Genera `results/metrics-go-high.csv` con CPU y RAM de los contenedores.

## Estructura del proyecto

```
api-benchmarking-jmeter/
├── docs/
│   └── clean-architecture-reference.md   # Contrato único de dominio
├── shared/
│   ├── db-init/
│   │   └── 01-init.sql                  # DDL para los 4 stacks
│   └── jmeter/
│       ├── api-benchmark.jmx            # Test plan JMeter parametrizado
│       └── payload.json                 # Payload de prueba
├── scripts/
│   ├── run-load-test.sh                 # Wrapper para ejecutar JMeter
│   └── monitor.sh                       # Captura docker stats
├── go-stdlib/
│   ├── cmd/api/main.go
│   ├── internal/domain/
│   ├── internal/application/
│   ├── internal/adapter/in/
│   ├── internal/adapter/out/
│   ├── internal/infrastructure/
│   ├── go.mod
│   ├── Dockerfile
│   └── docker-compose.yml
├── python-flask/
│   ├── src/domain/
│   ├── src/application/
│   ├── src/adapter/in/
│   ├── src/adapter/out/
│   ├── src/infrastructure/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
├── nodejs-nestjs/
│   ├── src/domain/
│   ├── src/application/
│   ├── src/adapter/in/
│   ├── src/adapter/out/
│   ├── src/infrastructure/
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   └── docker-compose.yml
└── java-springboot/
    ├── src/main/java/com/benchmark/orders/domain/
    ├── src/main/java/com/benchmark/orders/application/
    ├── src/main/java/com/benchmark/orders/adapter/in/
    ├── src/main/java/com/benchmark/orders/adapter/out/
    ├── src/main/java/com/benchmark/orders/infrastructure/
    ├── pom.xml
    ├── Dockerfile
    └── docker-compose.yml
```

## Comparación esperada de rendimiento (valores de referencia del taller)

| Escenario | Go | Python | Node.js | Java |
|-----------|----|--------|---------|------|
| **Baja (10 users)** | 5ms avg / 1100 tps | 22ms avg / 450 tps | 18ms avg / 520 tps | 9ms avg / 880 tps |
| **Media (50 users)** | 12ms avg / 1000 tps | 105ms avg / 310 tps | 72ms avg / 430 tps | 25ms avg / 800 tps |
| **Alta (100 users)** | 25ms avg / 900 tps | 260ms avg / 210 tps | 180ms avg / 320 tps | 55ms avg / 700 tps |

## Principios seguidos

- **Clean Architecture**: Domain → Application → Adapter → Infrastructure
- **Dependency Rule**: las capas internas no dependen de las externas
- **Sin ORM**: raw SQL vía driver nativo (pgx, psycopg2, pg, JdbcTemplate)
- **Pool de conexiones**: máximo 20 conexiones por stack
- **Transaccionalidad**: `orders` + `order_items` en la misma transacción
- **Aislamiento de BD**: cada stack tiene su propio PostgreSQL
- **Idempotencia de lógica**: misma lógica de negocio en los 4 lenguajes
