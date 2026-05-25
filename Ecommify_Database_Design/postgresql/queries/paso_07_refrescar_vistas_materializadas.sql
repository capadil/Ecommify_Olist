-- Ecommify Database Design
-- Paso 07: poblar o refrescar vistas materializadas analiticas.
-- El primer refresh debe ejecutarse sin CONCURRENTLY porque las vistas se crearon WITH NO DATA.
-- Despues del primer poblamiento y con indices unicos, el equipo puede evaluar CONCURRENTLY.

SET search_path TO ecommify, public;

REFRESH MATERIALIZED VIEW mv_sales_by_category_monthly;
REFRESH MATERIALIZED VIEW mv_customer_segments;
REFRESH MATERIALIZED VIEW mv_seller_performance_monthly;
REFRESH MATERIALIZED VIEW mv_geo_sales_summary;

