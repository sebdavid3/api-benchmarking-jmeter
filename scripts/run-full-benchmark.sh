#!/bin/bash
# ============================================================
# Orquestador completo de benchmarking para un stack
# Uso: ./scripts/run-full-benchmark.sh <stack> <port>
# Ejemplo: ./scripts/run-full-benchmark.sh python 5001
# ============================================================
set -euo pipefail

STACK="${1:?USO: $0 <stack> <port>}"
PORT="${2:?Falta el puerto de la API}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
RESULTS_DIR="${PROJECT_ROOT}/results"
mkdir -p "${RESULTS_DIR}"

COMPOSE_FILE="${PROJECT_ROOT}/${STACK}/docker-compose.yml"
if [[ ! -f "${COMPOSE_FILE}" ]]; then
    echo "Error: No existe ${COMPOSE_FILE}" >&2
    exit 1
fi

SCENARIOS=(low medium high stress)

# ============================================================
# Funciones auxiliares
# ============================================================

healthcheck_api() {
    local port="$1"
    local max_attempts=30
    local delay=2
    for i in $(seq 1 ${max_attempts}); do
        if curl -sf "http://localhost:${port}/health" > /dev/null 2>&1; then
            echo "[health] API en puerto ${port} responde OK"
            return 0
        fi
        echo "[health] Intento $i/${max_attempts}... esperando API en puerto ${port}"
        sleep ${delay}
    done
    echo "[health] ERROR: API no respondió después de ${max_attempts} intentos" >&2
    return 1
}

cleanup_stack() {
    echo "[cleanup] Bajando stack ${STACK}..."
    docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans 2>/dev/null || true
}

trap cleanup_stack EXIT

# ============================================================
# 1. Limpiar entorno previo
# ============================================================
echo "========================================"
echo " Benchmark completo: ${STACK}"
echo " Puerto:            ${PORT}"
echo "========================================"

cleanup_stack

# ============================================================
# 2. Levantar stack
# ============================================================
echo "[build] Levantando stack ${STACK}..."
docker compose -f "${COMPOSE_FILE}" up -d --build

# ============================================================
# 3. Esperar a que la API esté lista
# ============================================================
healthcheck_api "${PORT}"

# ============================================================
# 4. Smoke test
# ============================================================
echo "[smoke] Ejecutando smoke test..."
SMOKE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${PORT}/api/orders" \
    -H 'Content-Type: application/json' \
    -d @"${PROJECT_ROOT}/shared/jmeter/payload.json")

HTTP_CODE=$(echo "${SMOKE_RESPONSE}" | tail -n1)
BODY=$(echo "${SMOKE_RESPONSE}" | sed '$d')

if [[ "${HTTP_CODE}" != "200" ]]; then
    echo "[smoke] ERROR: Status ${HTTP_CODE}, body: ${BODY}" >&2
    exit 1
fi

if ! echo "${BODY}" | grep -q '"orderId"'; then
    echo "[smoke] ERROR: Response no contiene orderId" >&2
    exit 1
fi

echo "[smoke] OK - Response: ${BODY}"

# ============================================================
# 5. Ejecutar benchmarks por escenario
# ============================================================
for SCENARIO in "${SCENARIOS[@]}"; do
    echo ""
    echo "========================================"
    echo " Escenario: ${SCENARIO}"
    echo "========================================"

    # Iniciar monitoreo en background
    MONITOR_PID=""
    "${SCRIPT_DIR}/monitor.sh" "${STACK}" "${SCENARIO}" &
    MONITOR_PID=$!

    # Pequeña pausa para que monitor arranque
    sleep 2

    # Ejecutar JMeter
    "${SCRIPT_DIR}/run-load-test.sh" "${STACK}" "${PORT}" "${SCENARIO}"

    # Detener monitoreo
    if [[ -n "${MONITOR_PID}" ]] && kill -0 "${MONITOR_PID}" 2>/dev/null; then
        kill "${MONITOR_PID}" 2>/dev/null || true
        wait "${MONITOR_PID}" 2>/dev/null || true
    fi

done

# ============================================================
# 6. Recopilar evidencias de Docker stats finales
# ============================================================
echo ""
echo "[report] Estado final de contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# ============================================================
# 7. Bajar stack
# ============================================================
cleanup_stack

echo ""
echo "========================================"
echo " Benchmark completo finalizado"
echo " Resultados en: ${RESULTS_DIR}/"
echo "========================================"
