#!/bin/bash
# ============================================================
# Ejecuta una prueba de carga JMeter contra un stack específico
# Uso: ./scripts/run-load-test.sh <stack> <port> <scenario>
# Ejemplo: ./scripts/run-load-test.sh go 5004 high
# ============================================================
set -euo pipefail

STACK="${1:?USO: $0 <stack> <port> <scenario>}"
PORT="${2:?Falta el puerto de la API}"
SCENARIO="${3:?Falta escenario (low|medium|high)}"

JMX="shared/jmeter/api-benchmark.jmx"
JMETER_HOME="${JMETER_HOME:-/opt/apache-jmeter}"
RESULTS_DIR="results"
mkdir -p "${RESULTS_DIR}"

echo "============================================"
echo " Stack:    ${STACK}"
echo " Puerto:   ${PORT}"
echo " Escenario: ${SCENARIO}"
echo "============================================"

"${JMETER_HOME}/bin/jmeter" -n \
    -t "${JMX}" \
    -JapiPort="${PORT}" \
    -JstackName="${STACK}" \
    -Jscenario="${SCENARIO}" \
    -l "${RESULTS_DIR}/${STACK}-${SCENARIO}.csv" \
    -e -o "${RESULTS_DIR}/${STACK}-${SCENARIO}-report"

echo ""
echo "Resultados crudos: ${RESULTS_DIR}/${STACK}-${SCENARIO}.csv"
echo "Reporte HTML:      ${RESULTS_DIR}/${STACK}-${SCENARIO}-report/index.html"
