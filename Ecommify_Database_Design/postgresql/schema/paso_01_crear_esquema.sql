-- Ecommify Database Design
-- Paso 01: crear esquema base de PostgreSQL y habilitar extensiones adoptadas.
-- Decision: pg_trgm se habilita para soportar indices de similitud textual.
-- Decision: PostGIS se habilita para soportar geografia derivada e indexada en geolocation_clean.
-- JSONB y arrays son tipos nativos de PostgreSQL, no extensiones.

CREATE SCHEMA IF NOT EXISTS ecommify;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS postgis;

SET search_path TO ecommify, public;

COMMENT ON SCHEMA ecommify IS
  'Fuente de verdad transaccional de Ecommify. MongoDB consume documentos analiticos derivados.';
