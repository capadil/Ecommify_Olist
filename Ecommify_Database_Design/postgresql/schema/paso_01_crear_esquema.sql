-- Ecommify Database Design
-- Paso 01: crear esquema base de PostgreSQL.
-- Decision: no se habilitan extensiones obligatorias de PostgreSQL en el diseno inicial.
-- JSONB y arrays son tipos nativos de PostgreSQL, no extensiones.

CREATE SCHEMA IF NOT EXISTS ecommify;

SET search_path TO ecommify, public;

COMMENT ON SCHEMA ecommify IS
  'Fuente de verdad transaccional de Ecommify. MongoDB consume documentos analiticos derivados.';

