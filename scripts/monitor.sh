#!/bin/bash
# ============================================================
# Monitorea CPU/RAM de los contenedores Docker durante pruebas
# Uso: ./scripts/monitor.sh <stack> <scenario>
# Ejemplo: ./scripts/monitor.sh go high
# ============================================================
set -euo pipefail

STACK="${1:?USO: $0 <stack> <scenario>}"
SCENARIO="${2:?Falta escenario (low|medium|high)}"

# Mapeo de stack a nombres de contenedores API y DB
declare -A API_CONTAINER=(
    [go]=api-go
    [python]=api-python
    [nodejs]=api-nodejs
    [java]=api-java
)
declare -A DB_CONTAINER=(
    [go]=db-go
    [python]=db-python
    [nodejs]=db-nodejs
    [java]=db-java
)

API_NAME="${API_CONTAINER[${STACK}]:-}"
DB_NAME="${DB_CONTAINER[${STACK}]:-}"

if [[ -z "${API_NAME}" || -z "${DB_NAME}" ]]; then
    echo "Error: stack '${STACK}' no reconocido. Usa: go, python, nodejs, java" >&2
    exit 1
fi

RESULTS_DIR="results"
mkdir -p "${RESULTS_DIR}"

OUT="${RESULTS_DIR}/metrics-${STACK}-${SCENARIO}.csv"

echo "timestamp,container,cpu_percent,mem_usage,mem_percent" > "${OUT}"

echo "[monitor] Capturando métricas cada 2s para ${API_NAME} y ${DB_NAME} -> ${OUT}"
echo "[monitor] Ctrl+C para detener"

while true; do
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" \
        "${API_NAME}" "${DB_NAME}" \
        | while IFS= read -r line; do
              echo "${timestamp},${line}" >> "${OUT}"
          done
    sleep 2
done
