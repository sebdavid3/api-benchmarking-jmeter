#!/bin/bash
# ============================================================
# Extrae métricas clave de los CSV generados por JMeter
# y genera tablas Markdown listas para copiar al informe.
# Uso: ./scripts/extract-metrics.sh
# ============================================================
set -euo pipefail

RESULTS_DIR="results"
REPORT_FILE="docs/INFORME-AUTO.md"

if [[ ! -d "${RESULTS_DIR}" ]]; then
    echo "No existe carpeta ${RESULTS_DIR}. Ejecuta los benchmarks primero." >&2
    exit 1
fi

SCENARIOS=(low medium high stress)
SCENARIO_NAMES=("Baja carga (10 usuarios)" "Media carga (50 usuarios)" "Alta carga (100 usuarios)" "Estrés (150 usuarios)")

STACKS=(python go nodejs java)
STACK_LABELS=("Flask (Python)" "Go (stdlib)" "NestJS (Node)" "Spring Boot (Java)")

echo "# Informe de Resultados — Benchmark de APIs" > "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "> Generado automáticamente desde los CSV de JMeter" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "---" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# ============================================================
# 1. Rendimiento por stack y escenario
# ============================================================
echo "## 1. Rendimiento por Stack y Escenario" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

for i in "${!SCENARIOS[@]}"; do
    SCENARIO="${SCENARIOS[$i]}"
    NAME="${SCENARIO_NAMES[$i]}"

    echo "### ${NAME}" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    echo "| Stack | Avg (ms) | P95 (ms) | Throughput (req/s) | % Error |" >> "${REPORT_FILE}"
    echo "|-------|----------|----------|--------------------|---------|" >> "${REPORT_FILE}"

    for j in "${!STACKS[@]}"; do
        STACK="${STACKS[$j]}"
        LABEL="${STACK_LABELS[$j]}"
        CSV="${RESULTS_DIR}/${STACK}-${SCENARIO}.csv"

        if [[ -f "${CSV}" ]]; then
            # Extraer métricas del CSV de JMeter
            # Formato JMeter CSV: timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect
            # elapsed = response time in ms
            
            # Calcular promedio (success es columna 8)
            AVG=$(awk -F',' 'NR>1 && $8=="true" {sum+=$2; count++} END {if(count>0) printf "%.1f", sum/count; else print "N/A"}' "${CSV}")
            
            # Calcular P95 (aproximado ordenando)
            P95=$(awk -F',' 'NR>1 && $8=="true" {print $2}' "${CSV}" | sort -n | awk '{
                a[NR] = $1
            } END {
                if (NR == 0) { print "N/A"; exit }
                idx = int(NR * 0.95)
                if (idx < 1) idx = 1
                if (idx > NR) idx = NR
                print a[idx]
            }')
            
            # Throughput: requests / duration_seconds
            # JMeter CSV ya tiene timestamp. Duration = (last - first) / 1000
            THROUGHPUT=$(awk -F',' 'NR>1 {count++; if(min==0 || $1<min) min=$1; if(max==0 || $1>max) max=$1} END {
                if(count==0) {print "N/A"; exit}
                duration = (max - min) / 1000
                if(duration <= 0) duration = 1
                printf "%.1f", count / duration
            }' "${CSV}")
            
            # % Error (success es columna 8)
            ERROR_PCT=$(awk -F',' 'NR>1 {total++; if($8!="true") err++} END {if(total==0) print "N/A"; else printf "%.2f%%", (err/total)*100}' "${CSV}")
            
            echo "| ${LABEL} | ${AVG} | ${P95} | ${THROUGHPUT} | ${ERROR_PCT} |" >> "${REPORT_FILE}"
        else
            echo "| ${LABEL} | N/A | N/A | N/A | N/A |" >> "${REPORT_FILE}"
        fi
    done
    echo "" >> "${REPORT_FILE}"
done

# ============================================================
# 2. Consumo del sistema (template — requiere datos de monitor.sh)
# ============================================================
echo "## 2. Consumo del Sistema (CPU/RAM)" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "> Nota: esta tabla se completa manualmente a partir de los CSV generados por monitor.sh y las capturas de htop/docker stats." >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

for i in "${!SCENARIOS[@]}"; do
    SCENARIO="${SCENARIOS[$i]}"
    NAME="${SCENARIO_NAMES[$i]}"
    
    echo "### ${NAME}" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    echo "| Stack | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones |" >> "${REPORT_FILE}"
    echo "|-------|-------------|---------------|------------|--------------|---------------|" >> "${REPORT_FILE}"
    
    for j in "${!STACKS[@]}"; do
        LABEL="${STACK_LABELS[$j]}"
        echo "| ${LABEL} | - | - | - | - | (completar desde monitor.sh + docker stats) |" >> "${REPORT_FILE}"
    done
    echo "" >> "${REPORT_FILE}"
done

# ============================================================
# 3. Conclusiones (template)
# ============================================================
echo "## 3. Conclusiones" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "### Rendimiento" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "1. **¿Cuál stack tuvo mejor latencia promedio?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "2. **¿Cuál mantuvo el mejor throughput en cargas altas?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "3. **¿Qué lenguaje fue más estable?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "### Eficiencia" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "4. **¿Algún stack mostró errores bajo alta carga?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "5. **¿Qué puede explicar esas fallas?**" >> "${REPORT_FILE}"
echo "   - *(completar: GC, GIL, thread model, etc.)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "### Recomendación para producción" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "6. **¿Cuál stack recomendarían para alto desempeño?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "7. **¿Cuál es más fácil de implementar pero sacrifica rendimiento?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "8. **¿Cuál ofrece mejor balance entre sencillez y velocidad?**" >> "${REPORT_FILE}"
echo "   - *(completar)*" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

echo "---" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "> Archivo generado en: ${REPORT_FILE}" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"
echo "> Los valores de rendimiento se extrajeron automáticamente de los CSV en ${RESULTS_DIR}/" >> "${REPORT_FILE}"
echo "> Los valores de consumo del sistema deben completarse manualmente desde monitor.sh y capturas de pantalla." >> "${REPORT_FILE}"

echo "========================================"
echo " Informe generado: ${REPORT_FILE}"
echo "========================================"
