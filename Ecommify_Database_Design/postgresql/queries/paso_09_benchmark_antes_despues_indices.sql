-- Ecommify Database Design
-- Paso 09: benchmark comparativo antes/despues para PostgreSQL.
--
-- Objetivo:
--   Guardar evidencias cuantitativas en una tabla, no solo imprimir EXPLAIN
--   en consola. Esto permite construir tablas y graficos comparativos despues.
--
-- Estrategia:
--   1. Baseline controlado: se deshabilitan indexscan y bitmapscan en la sesion.
--   2. Optimizado: se restauran parametros normales del optimizador.
--   3. Cada medicion se inserta en ecommify.benchmark_results.
--
-- Ejecucion desde docker/:
--   docker compose exec postgres psql -U ecommify_user -d ecommify_db -f /workspace/postgresql/queries/paso_09_benchmark_antes_despues_indices.sql

SET search_path TO ecommify, public;

CREATE TABLE IF NOT EXISTS benchmark_results (
    benchmark_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id TEXT NOT NULL,
    engine TEXT NOT NULL,
    benchmark_name TEXT NOT NULL,
    scenario TEXT NOT NULL,
    query_label TEXT NOT NULL,
    expected_access_path TEXT,
    execution_time_ms NUMERIC(14, 3),
    planning_time_ms NUMERIC(14, 3),
    top_node_type TEXT,
    estimated_rows BIGINT,
    actual_rows BIGINT,
    shared_hit_blocks BIGINT,
    shared_read_blocks BIGINT,
    plan_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION run_postgres_benchmark(
    p_run_id TEXT,
    p_benchmark_name TEXT,
    p_scenario TEXT,
    p_query_label TEXT,
    p_expected_access_path TEXT,
    p_sql TEXT
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    explain_row RECORD;
    explain_json JSONB;
    plan_root JSONB;
BEGIN
    FOR explain_row IN EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || p_sql
    LOOP
        explain_json := explain_row."QUERY PLAN"::jsonb;
    END LOOP;

    plan_root := explain_json -> 0 -> 'Plan';

    INSERT INTO benchmark_results (
        run_id,
        engine,
        benchmark_name,
        scenario,
        query_label,
        expected_access_path,
        execution_time_ms,
        planning_time_ms,
        top_node_type,
        estimated_rows,
        actual_rows,
        shared_hit_blocks,
        shared_read_blocks,
        plan_json
    )
    VALUES (
        p_run_id,
        'PostgreSQL',
        p_benchmark_name,
        p_scenario,
        p_query_label,
        p_expected_access_path,
        (explain_json -> 0 ->> 'Execution Time')::NUMERIC,
        (explain_json -> 0 ->> 'Planning Time')::NUMERIC,
        plan_root ->> 'Node Type',
        NULLIF(plan_root ->> 'Plan Rows', '')::BIGINT,
        NULLIF(plan_root ->> 'Actual Rows', '')::BIGINT,
        COALESCE(NULLIF(plan_root ->> 'Shared Hit Blocks', '')::BIGINT, 0),
        COALESCE(NULLIF(plan_root ->> 'Shared Read Blocks', '')::BIGINT, 0),
        explain_json
    );
END;
$$;

DO $$
DECLARE
    v_run_id TEXT := 'pg_' || to_char(clock_timestamp(), 'YYYYMMDD_HH24MISS_MS');
BEGIN
    -- Benchmark 1: consulta OLTP por order_id.
    PERFORM set_config('enable_indexscan', 'off', true);
    PERFORM set_config('enable_bitmapscan', 'off', true);

    PERFORM run_postgres_benchmark(
        v_run_id,
        'OLTP order lookup',
        'baseline_without_indexscan_bitmapscan',
        'order_by_order_id_with_customer_payments',
        'Forced sequential/hash access for baseline',
        $SQL$
        SELECT
            o.order_id,
            o.order_status,
            c.customer_id,
            op.payment_value
        FROM orders o
        JOIN customers c ON c.customer_sk = o.customer_sk
        LEFT JOIN order_payments op ON op.order_sk = o.order_sk
        WHERE o.order_id = 'e481f51cbdc54678b7cc49136f2d6af7'
        $SQL$
    );

    PERFORM set_config('enable_indexscan', 'on', true);
    PERFORM set_config('enable_bitmapscan', 'on', true);

    PERFORM run_postgres_benchmark(
        v_run_id,
        'OLTP order lookup',
        'optimized_with_indexes',
        'order_by_order_id_with_customer_payments',
        'idx_orders_order_id, customers_pkey, idx_order_payments_order_sk',
        $SQL$
        SELECT
            o.order_id,
            o.order_status,
            c.customer_id,
            op.payment_value
        FROM orders o
        JOIN customers c ON c.customer_sk = o.customer_sk
        LEFT JOIN order_payments op ON op.order_sk = o.order_sk
        WHERE o.order_id = 'e481f51cbdc54678b7cc49136f2d6af7'
        $SQL$
    );

    -- Benchmark 2: busqueda aproximada con pg_trgm.
    PERFORM set_config('enable_indexscan', 'off', true);
    PERFORM set_config('enable_bitmapscan', 'off', true);

    PERFORM run_postgres_benchmark(
        v_run_id,
        'pg_trgm customer city search',
        'baseline_without_indexscan_bitmapscan',
        'customer_city_similarity_sao_paulo',
        'Forced sequential scan for baseline',
        $SQL$
        SELECT
            customer_id,
            customer_city,
            customer_state
        FROM customers
        WHERE customer_city % 'sao paulo'
        ORDER BY similarity(customer_city, 'sao paulo') DESC
        LIMIT 20
        $SQL$
    );

    PERFORM set_config('enable_indexscan', 'on', true);
    PERFORM set_config('enable_bitmapscan', 'on', true);

    PERFORM run_postgres_benchmark(
        v_run_id,
        'pg_trgm customer city search',
        'optimized_with_indexes',
        'customer_city_similarity_sao_paulo',
        'idx_customers_city_trgm',
        $SQL$
        SELECT
            customer_id,
            customer_city,
            customer_state
        FROM customers
        WHERE customer_city % 'sao paulo'
        ORDER BY similarity(customer_city, 'sao paulo') DESC
        LIMIT 20
        $SQL$
    );

    -- Benchmark 3: consulta espacial PostGIS.
    PERFORM set_config('enable_indexscan', 'off', true);
    PERFORM set_config('enable_bitmapscan', 'off', true);

    PERFORM run_postgres_benchmark(
        v_run_id,
        'PostGIS radius search',
        'baseline_without_indexscan_bitmapscan',
        'geolocation_within_5km_sao_paulo',
        'Forced sequential scan for baseline',
        $SQL$
        SELECT
            geolocation_zip_code_prefix,
            geolocation_city,
            geolocation_state
        FROM geolocation_clean
        WHERE ST_DWithin(
            geog,
            ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography,
            5000
        )
        LIMIT 20
        $SQL$
    );

    PERFORM set_config('enable_indexscan', 'on', true);
    PERFORM set_config('enable_bitmapscan', 'on', true);

    PERFORM run_postgres_benchmark(
        v_run_id,
        'PostGIS radius search',
        'optimized_with_indexes',
        'geolocation_within_5km_sao_paulo',
        'idx_geolocation_clean_geog_gist',
        $SQL$
        SELECT
            geolocation_zip_code_prefix,
            geolocation_city,
            geolocation_state
        FROM geolocation_clean
        WHERE ST_DWithin(
            geog,
            ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography,
            5000
        )
        LIMIT 20
        $SQL$
    );

    -- Benchmark 4: lectura sobre vista materializada.
    PERFORM run_postgres_benchmark(
        v_run_id,
        'Materialized view sales dashboard',
        'materialized_view_read',
        'sales_by_category_2018_top10',
        'mv_sales_by_category_monthly',
        $SQL$
        SELECT
            sales_month,
            category_name,
            total_value
        FROM mv_sales_by_category_monthly
        WHERE sales_month BETWEEN DATE '2018-01-01' AND DATE '2018-12-01'
        ORDER BY total_value DESC
        LIMIT 10
        $SQL$
    );
END;
$$;
