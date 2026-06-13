#!/usr/bin/env bash
set -euo pipefail

printf '\n[Ecommify/PostgreSQL] Ejecutando scripts de esquema 01-05...\n'

SCHEMA_DIR="/workspace/postgresql/schema"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_DIR/paso_01_crear_esquema.sql"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_DIR/paso_02_crear_tablas_base.sql"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_DIR/paso_03_crear_indices.sql"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_DIR/paso_04_crear_triggers_updated_at.sql"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_DIR/paso_05_crear_vistas_materializadas.sql"

printf '[Ecommify/PostgreSQL] Esquema base inicializado correctamente.\n\n'