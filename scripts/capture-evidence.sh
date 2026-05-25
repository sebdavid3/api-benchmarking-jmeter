#!/bin/bash
# ============================================================
# Captura evidencias de docker ps y docker stats
# para cada stack. No ejecuta pruebas JMeter.
# Uso: ./scripts/capture-evidence.sh
# ============================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCIAS="${PROJECT_ROOT}/docs/evidencias"

STACKS=(
    "python:python-flask:api-python:db-python"
    "go:go-stdlib:api-go:db-go"
    "nodejs:nodejs-nestjs:api-nodejs:db-nodejs"
    "java:java-springboot:api-java:db-java"
)

mkdir -p "${EVIDENCIAS}"

for entry in "${STACKS[@]}"; do
    IFS=: read -r name dir api_name db_name <<< "$entry"
    
    echo ""
    echo "============================================"
    echo " Capturando evidencias para: ${name}"
    echo "============================================"
    
    # Levantar contenedores
    echo "[1/4] Levantando contenedores..."
    docker compose -f "${PROJECT_ROOT}/${dir}/docker-compose.yml" up -d --build 2>&1 | tail -3
    
    # Esperar a que estén healthy
    echo "[2/4] Esperando health checks..."
    for i in $(seq 1 30); do
        api_status=$(docker inspect --format='{{.State.Health.Status}}' "${api_name}" 2>/dev/null || echo "starting")
        db_status=$(docker inspect --format='{{.State.Health.Status}}' "${db_name}" 2>/dev/null || echo "starting")
        if [[ "$api_status" == "healthy" && "$db_status" == "healthy" ]]; then
            echo "   Ambos healthy!"
            break
        fi
        sleep 2
    done
    sleep 3
    
    # Capturar docker ps
    echo "[3/4] Capturando docker ps y docker stats..."
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "${EVIDENCIAS}/${name}/docker-ps.txt"
    
    # Capturar docker stats (3 snapshots con 2s de intervalo)
    for i in 1 2 3; do
        echo "--- snapshot ${i} ---" >> "${EVIDENCIAS}/${name}/docker-stats.txt"
        docker stats --no-stream "${api_name}" "${db_name}" >> "${EVIDENCIAS}/${name}/docker-stats.txt" 2>&1
        sleep 2
    done
    
    echo "[4/4] Guardado en docs/evidencias/${name}/"
    
    # Apagar contenedores
    echo "Apagando contenedores..."
    docker compose -f "${PROJECT_ROOT}/${dir}/docker-compose.yml" down 2>&1 | tail -2
done

echo ""
echo "============================================"
echo " Evidencias capturadas en docs/evidencias/"
echo "============================================"
ls -la "${EVIDENCIAS}"/*/docker-*.txt
