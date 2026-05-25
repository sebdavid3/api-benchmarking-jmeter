#!/bin/bash
# ============================================================
# Ejecuta una prueba de carga JMeter contra un stack específico
# Uso: ./scripts/run-load-test.sh <stack> <port> <scenario>
# Ejemplo: ./scripts/run-load-test.sh go 5004 high
# ============================================================
set -euo pipefail

STACK="${1:?USO: $0 <stack> <port> <scenario>}"
PORT="${2:?Falta el puerto de la API}"
SCENARIO="${3:?Falta escenario (low|medium|high|stress)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

JMX="${PROJECT_ROOT}/shared/jmeter/api-benchmark-${SCENARIO}.jmx"
RESULTS_DIR="${PROJECT_ROOT}/results"
mkdir -p "${RESULTS_DIR}"

if [[ ! -f "${JMX}" ]]; then
    echo "Error: No existe archivo JMeter para escenario '${SCENARIO}': ${JMX}" >&2
    echo "Escenarios válidos: low, medium, high, stress" >&2
    exit 1
fi

# ============================================================
# Detectar Java / JMeter
# ============================================================
JMETER_HOME="${JMETER_HOME:-/opt/apache-jmeter}"

if [[ ! -x "${JMETER_HOME}/bin/jmeter" ]]; then
    if [[ -x "/tmp/apache-jmeter-5.6.3/bin/jmeter" ]]; then
        JMETER_HOME="/tmp/apache-jmeter-5.6.3"
    elif command -v java >/dev/null 2>&1; then
        echo "[warn] JMETER_HOME no encontrado, pero Java sí. Instala JMeter en /opt/apache-jmeter o define JMETER_HOME." >&2
        exit 1
    elif [[ -x "/tmp/jdk-21.0.4+7-jre/bin/java" ]]; then
        export JAVA_HOME="/tmp/jdk-21.0.4+7-jre"
        export PATH="${JAVA_HOME}/bin:${PATH}"
        if [[ -x "/tmp/apache-jmeter-5.6.3/bin/jmeter" ]]; then
            JMETER_HOME="/tmp/apache-jmeter-5.6.3"
        else
            echo "[error] No se encontró JMeter." >&2
            exit 1
        fi
    else
        echo "[error] No se encontró Java ni JMeter." >&2
        exit 1
    fi
fi

echo "============================================"
echo " Stack:      ${STACK}"
echo " Puerto:     ${PORT}"
echo " Escenario:  ${SCENARIO}"
echo " JMeter:     ${JMETER_HOME}"
echo " Plan:       ${JMX}"
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
