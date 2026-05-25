# Informe de Resultados — Benchmark de APIs

> Generado automáticamente desde los CSV de JMeter

---

## 1. Rendimiento por Stack y Escenario

### Baja carga (10 usuarios)

| Stack | Avg (ms) | P95 (ms) | Throughput (req/s) | % Error |
|-------|----------|----------|--------------------|---------|
| Flask (Python) | 17,1 | 32 | 563,3 | 0,00% |
| Go (stdlib) | 4,5 | 11 | 2111,4 | 0,00% |
| NestJS (Node) | 9,5 | 17 | 1032,0 | 0,00% |
| Spring Boot (Java) | 4,1 | 11 | 2320,9 | 0,00% |

### Media carga (50 usuarios)

| Stack | Avg (ms) | P95 (ms) | Throughput (req/s) | % Error |
|-------|----------|----------|--------------------|---------|
| Flask (Python) | 86,3 | 146 | 566,3 | 0,00% |
| Go (stdlib) | 21,3 | 35 | 2274,8 | 0,00% |
| NestJS (Node) | 48,5 | 71 | 1005,3 | 0,00% |
| Spring Boot (Java) | 14,3 | 29 | 3398,7 | 0,00% |

### Alta carga (100 usuarios)

| Stack | Avg (ms) | P95 (ms) | Throughput (req/s) | % Error |
|-------|----------|----------|--------------------|---------|
| Flask (Python) | 150,4 | 249 | 646,4 | 0,00% |
| Go (stdlib) | 40,6 | 78 | 2384,7 | 0,00% |
| NestJS (Node) | 87,0 | 119 | 1118,0 | 0,00% |
| Spring Boot (Java) | 32,1 | 72 | 3011,6 | 0,00% |

### Estrés (150 usuarios)

| Stack | Avg (ms) | P95 (ms) | Throughput (req/s) | % Error |
|-------|----------|----------|--------------------|---------|
| Flask (Python) | 292,9 | 508 | 496,3 | 0,00% |
| Go (stdlib) | 39,7 | 52 | 3624,6 | 0,00% |
| NestJS (Node) | 144,2 | 184 | 1007,9 | 0,00% |
| Spring Boot (Java) | 55,1 | 131 | 0,0 | 0,22% |

## 2. Consumo del Sistema (CPU/RAM)

> Nota: esta tabla se completa manualmente a partir de los CSV generados por monitor.sh y las capturas de htop/docker stats.

### Baja carga (10 usuarios)

| Stack | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones |
|-------|-------------|---------------|------------|--------------|---------------|
| Flask (Python) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Go (stdlib) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| NestJS (Node) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Spring Boot (Java) | - | - | - | - | (completar desde monitor.sh + docker stats) |

### Media carga (50 usuarios)

| Stack | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones |
|-------|-------------|---------------|------------|--------------|---------------|
| Flask (Python) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Go (stdlib) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| NestJS (Node) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Spring Boot (Java) | - | - | - | - | (completar desde monitor.sh + docker stats) |

### Alta carga (100 usuarios)

| Stack | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones |
|-------|-------------|---------------|------------|--------------|---------------|
| Flask (Python) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Go (stdlib) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| NestJS (Node) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Spring Boot (Java) | - | - | - | - | (completar desde monitor.sh + docker stats) |

### Estrés (150 usuarios)

| Stack | CPU API (%) | RAM API (MiB) | CPU DB (%) | RAM DB (MiB) | Observaciones |
|-------|-------------|---------------|------------|--------------|---------------|
| Flask (Python) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Go (stdlib) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| NestJS (Node) | - | - | - | - | (completar desde monitor.sh + docker stats) |
| Spring Boot (Java) | - | - | - | - | (completar desde monitor.sh + docker stats) |

## 3. Conclusiones

### Rendimiento

1. **¿Cuál stack tuvo mejor latencia promedio?**
   - *(completar)*

2. **¿Cuál mantuvo el mejor throughput en cargas altas?**
   - *(completar)*

3. **¿Qué lenguaje fue más estable?**
   - *(completar)*

### Eficiencia

4. **¿Algún stack mostró errores bajo alta carga?**
   - *(completar)*

5. **¿Qué puede explicar esas fallas?**
   - *(completar: GC, GIL, thread model, etc.)*

### Recomendación para producción

6. **¿Cuál stack recomendarían para alto desempeño?**
   - *(completar)*

7. **¿Cuál es más fácil de implementar pero sacrifica rendimiento?**
   - *(completar)*

8. **¿Cuál ofrece mejor balance entre sencillez y velocidad?**
   - *(completar)*

---

> Archivo generado en: docs/INFORME-AUTO.md

> Los valores de rendimiento se extrajeron automáticamente de los CSV en results/
> Los valores de consumo del sistema deben completarse manualmente desde monitor.sh y capturas de pantalla.
