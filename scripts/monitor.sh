#!/bin/bash
# ============================================================
# Monitorea CPU/RAM de los contenedores Docker durante pruebas
# Uso: ./scripts/monitor.sh <stack> <scenario>
# Ejemplo: ./scripts/monitor.sh go high
# ============================================================
set -euo pipefail

STACK="${1:?USO: $0 <stack> <scenario>}"
SCENARIO="${2:?Falta escenario (low|medium|high)}"

RESULTS_DIR="results"
mkdir -p "${RESULTS_DIR}"

OUT="${RESULTS_DIR}/metrics-${STACK}-${SCENARIO}.csv"

echo "timestamp,container,cpu_percent,mem_usage,mem_percent" > "${OUT}"

echo "[monitor] Capturando métricas cada 2s -> ${OUT}"
echo "[monitor] Ctrl+C para detener"

while true; do
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" \
        | while IFS= read -r line; do
              echo "${timestamp},${line}" >> "${OUT}"
          done
    sleep 2
done
