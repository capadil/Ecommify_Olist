"""
Sincronizador PostgreSQL -> MongoDB para Ecommify.

Este script materializa en MongoDB documentos derivados desde PostgreSQL.
La decision arquitectonica del proyecto se conserva: PostgreSQL sigue siendo la
fuente de verdad; MongoDB recibe copias orientadas a lectura y analitica.

Ejecucion recomendada desde Docker:
    docker compose run --rm mongo_sync
"""

from __future__ import annotations

import os
from datetime import date, datetime, time, timezone
from decimal import Decimal
from typing import Any, Iterable
from urllib.parse import quote_plus

import psycopg
from psycopg.rows import dict_row
from pymongo import MongoClient, UpdateOne


# Tamano de lote para no guardar todos los documentos en memoria al mismo tiempo.
BATCH_SIZE = int(os.getenv("SYNC_BATCH_SIZE", "1000"))


# Nombre de la base documental definida en los validadores de MongoDB.
MONGO_DB_NAME = os.getenv("MONGO_DB", "ecommify_analytics")


# Timestamp unico para marcar cuando se genero esta sincronizacion.
SYNCED_AT = datetime.now(timezone.utc)


def postgres_dsn() -> str:
    """Construye la cadena de conexion a PostgreSQL.

    Por defecto usa las variables del ambiente Docker local. Para ejecuciones
    cloud acepta un DSN completo mediante POSTGRES_DSN o SUPABASE_DATABASE_URL.
    """
    cloud_dsn = os.getenv("POSTGRES_DSN") or os.getenv("SUPABASE_DATABASE_URL")
    if cloud_dsn:
        return cloud_dsn

    host = os.getenv("POSTGRES_HOST", "postgres")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "ecommify_db")
    user = os.getenv("POSTGRES_USER", "ecommify_user")
    password = os.getenv("POSTGRES_PASSWORD", "ecommify_password")
    return f"host={host} port={port} dbname={db} user={user} password={password}"


def mongo_uri() -> str:
    """Construye la URI de MongoDB.

    Por defecto usa el MongoDB local del compose. Para Atlas acepta una URI
    completa mediante MONGO_URI o ATLAS_URI. Si la URI cloud no trae usuario
    y password embebidos, permite recibirlos en ATLAS_USER y ATLAS_USER_PASS.
    """
    cloud_uri = os.getenv("MONGO_URI") or os.getenv("ATLAS_URI")
    if cloud_uri:
        user = os.getenv("ATLAS_USER")
        password = os.getenv("ATLAS_USER_PASS")
        authority = cloud_uri.split("://", 1)[1].split("/", 1)[0] if "://" in cloud_uri else ""
        if user and password and "@" not in authority:
            scheme, rest = cloud_uri.split("://", 1)
            return f"{scheme}://{quote_plus(user)}:{quote_plus(password)}@{rest}"
        return cloud_uri

    host = os.getenv("MONGO_HOST", "mongo")
    port = os.getenv("MONGO_PORT", "27017")
    user = os.getenv("MONGO_INITDB_ROOT_USERNAME", "ecommify_admin")
    password = os.getenv("MONGO_INITDB_ROOT_PASSWORD", "ecommify_password")
    return f"mongodb://{user}:{password}@{host}:{port}/?authSource=admin"


def to_mongo_value(value: Any) -> Any:
    """Convierte tipos de PostgreSQL a tipos seguros para BSON/MongoDB."""
    if isinstance(value, datetime):
        return value
    if isinstance(value, date):
        # BSON no acepta datetime.date puro; MongoDB requiere fecha con hora.
        return datetime.combine(value, time.min, tzinfo=timezone.utc)
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, list):
        return [to_mongo_value(item) for item in value]
    if isinstance(value, dict):
        return {key: to_mongo_value(item) for key, item in value.items()}
    return value


def clean_document(document: dict[str, Any]) -> dict[str, Any]:
    """Aplica conversion de tipos recursiva y elimina claves con valor None si no aportan."""
    return {key: to_mongo_value(value) for key, value in document.items()}


def batched(cursor: Iterable[dict[str, Any]], batch_size: int = BATCH_SIZE) -> Iterable[list[dict[str, Any]]]:
    """Agrupa filas del cursor para ejecutar escrituras masivas en MongoDB."""
    batch: list[dict[str, Any]] = []
    for row in cursor:
        batch.append(row)
        if len(batch) >= batch_size:
            yield batch
            batch = []
    if batch:
        yield batch


def bulk_upsert(collection, operations: list[UpdateOne], label: str) -> int:
    """Ejecuta un lote de upserts y retorna cuantas operaciones se enviaron."""
    if not operations:
        return 0
    collection.bulk_write(operations, ordered=False)
    print(f"[sync] {label}: {len(operations)} documentos procesados")
    return len(operations)


def sync_product_catalog(pg_conn, mongo_db) -> int:
    """Construye product_catalog desde productos, categorias, ventas y resenas."""
    sql = """
        SELECT
            p.product_id,
            ct.product_category_name,
            ct.product_category_name_english,
            p.product_weight_g,
            p.product_length_cm,
            p.product_height_cm,
            p.product_width_cm,
            p.specifications,
            p.photo_urls,
            COUNT(DISTINCT oi.order_sk) AS total_orders,
            COALESCE(SUM(oi.price + oi.freight_value), 0) AS total_revenue,
            COUNT(DISTINCT r.review_sk) AS review_count,
            AVG(r.review_score) AS avg_score
        FROM products p
        LEFT JOIN category_translation ct ON ct.category_sk = p.category_sk
        LEFT JOIN order_items oi ON oi.product_sk = p.product_sk
        LEFT JOIN order_reviews r ON r.order_sk = oi.order_sk
        GROUP BY
            p.product_id,
            ct.product_category_name,
            ct.product_category_name_english,
            p.product_weight_g,
            p.product_length_cm,
            p.product_height_cm,
            p.product_width_cm,
            p.specifications,
            p.photo_urls
        ORDER BY p.product_id;
    """
    total = 0
    collection = mongo_db.product_catalog
    with pg_conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql)
        for rows in batched(cur):
            operations = []
            for row in rows:
                document = clean_document({
                    "product_id": row["product_id"],
                    "category": {
                        "name": row["product_category_name"],
                        "translated_name": row["product_category_name_english"] or "uncategorized",
                    },
                    "dimensions": {
                        "weight_g": row["product_weight_g"],
                        "length_cm": row["product_length_cm"],
                        "height_cm": row["product_height_cm"],
                        "width_cm": row["product_width_cm"],
                    },
                    "specifications": row["specifications"] or {},
                    "photos": row["photo_urls"] or [],
                    "sales_metrics": {
                        "total_orders": row["total_orders"],
                        "total_revenue": row["total_revenue"],
                    },
                    "review_summary": {
                        "review_count": row["review_count"],
                        "avg_score": row["avg_score"],
                    },
                    "updated_at": SYNCED_AT,
                })
                operations.append(UpdateOne({"product_id": document["product_id"]}, {"$set": document}, upsert=True))
            total += bulk_upsert(collection, operations, "product_catalog")
    return total


def sync_customer_profiles(pg_conn, mongo_db) -> int:
    """Construye perfiles de cliente desde la vista materializada mv_customer_segments."""
    sql = """
        SELECT
            customer_id,
            customer_unique_id,
            customer_state,
            orders_count,
            total_payment_value,
            first_order_at,
            last_order_at,
            avg_review_score,
            customer_segment
        FROM mv_customer_segments
        ORDER BY customer_id;
    """
    total = 0
    collection = mongo_db.customer_profiles
    with pg_conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql)
        for rows in batched(cur):
            operations = []
            for row in rows:
                document = clean_document({
                    "customer_id": row["customer_id"],
                    "customer_unique_id": row["customer_unique_id"],
                    "location": {"state": row["customer_state"]},
                    "order_metrics": {
                        "orders_count": row["orders_count"],
                        "first_order_at": row["first_order_at"],
                        "last_order_at": row["last_order_at"],
                    },
                    "payment_summary": {"total_payment_value": row["total_payment_value"]},
                    "review_summary": {"avg_review_score": row["avg_review_score"]},
                    "segment": row["customer_segment"],
                    "updated_at": SYNCED_AT,
                })
                operations.append(UpdateOne({"customer_id": document["customer_id"]}, {"$set": document}, upsert=True))
            total += bulk_upsert(collection, operations, "customer_profiles")
    return total


def sync_seller_performance(pg_conn, mongo_db) -> int:
    """Construye un documento por vendedor con metricas mensuales embebidas."""
    sql = """
        SELECT
            seller_id,
            seller_state,
            jsonb_agg(
                jsonb_build_object(
                    'sales_month', sales_month,
                    'orders_count', orders_count,
                    'items_count', items_count,
                    'gross_sales', gross_sales,
                    'avg_review_score', avg_review_score
                ) ORDER BY sales_month
            ) AS monthly_metrics,
            SUM(orders_count) AS total_orders,
            SUM(items_count) AS total_items,
            SUM(gross_sales) AS total_gross_sales,
            AVG(avg_review_score) AS avg_review_score
        FROM mv_seller_performance_monthly
        GROUP BY seller_id, seller_state
        ORDER BY seller_id;
    """
    total = 0
    collection = mongo_db.seller_performance
    with pg_conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql)
        for rows in batched(cur):
            operations = []
            for row in rows:
                document = clean_document({
                    "seller_id": row["seller_id"],
                    "location": {"state": row["seller_state"]},
                    "monthly_metrics": row["monthly_metrics"] or [],
                    "review_summary": {"avg_review_score": row["avg_review_score"]},
                    "sales_summary": {
                        "total_orders": row["total_orders"],
                        "total_items": row["total_items"],
                        "total_gross_sales": row["total_gross_sales"],
                    },
                    "updated_at": SYNCED_AT,
                })
                operations.append(UpdateOne({"seller_id": document["seller_id"]}, {"$set": document}, upsert=True))
            total += bulk_upsert(collection, operations, "seller_performance")
    return total


def sync_geo_analytics(pg_conn, mongo_db) -> int:
    """Construye documentos geograficos agregados por estado, ciudad y mes."""
    sql = """
        SELECT
            customer_state,
            customer_city,
            sales_month,
            orders_count,
            total_payment_value
        FROM mv_geo_sales_summary
        ORDER BY customer_state, customer_city, sales_month;
    """
    total = 0
    collection = mongo_db.geo_analytics
    with pg_conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql)
        for rows in batched(cur):
            operations = []
            for row in rows:
                month_key = row["sales_month"].isoformat() if row["sales_month"] else "unknown"
                geo_key = f"{row['customer_state']}|{row['customer_city']}|{month_key}"
                document = clean_document({
                    "geo_key": geo_key,
                    "state": row["customer_state"],
                    "city": row["customer_city"],
                    "sales_month": row["sales_month"],
                    "sales_metrics": {
                        "orders_count": row["orders_count"],
                        "total_payment_value": row["total_payment_value"],
                    },
                    "customer_metrics": {},
                    "seller_metrics": {},
                    "updated_at": SYNCED_AT,
                })
                operations.append(UpdateOne({"geo_key": geo_key}, {"$set": document}, upsert=True))
            total += bulk_upsert(collection, operations, "geo_analytics")
    return total


def sync_review_documents(pg_conn, mongo_db) -> int:
    """Construye documentos de resenas enriquecidos con orden, cliente y productos."""
    sql = """
        SELECT
            r.review_id,
            o.order_id,
            r.review_score,
            r.review_comment_title,
            r.review_comment_message,
            r.review_creation_date,
            r.review_answer_timestamp,
            c.customer_id,
            c.customer_state,
            jsonb_agg(
                DISTINCT jsonb_build_object(
                    'product_id', p.product_id,
                    'category', ct.product_category_name_english
                )
            ) FILTER (WHERE p.product_id IS NOT NULL) AS product_context
        FROM order_reviews r
        JOIN orders o ON o.order_sk = r.order_sk
        JOIN customers c ON c.customer_sk = o.customer_sk
        LEFT JOIN order_items oi ON oi.order_sk = o.order_sk
        LEFT JOIN products p ON p.product_sk = oi.product_sk
        LEFT JOIN category_translation ct ON ct.category_sk = p.category_sk
        GROUP BY
            r.review_id,
            o.order_id,
            r.review_score,
            r.review_comment_title,
            r.review_comment_message,
            r.review_creation_date,
            r.review_answer_timestamp,
            c.customer_id,
            c.customer_state
        ORDER BY r.review_id, o.order_id;
    """
    total = 0
    collection = mongo_db.review_documents
    with pg_conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql)
        for rows in batched(cur):
            operations = []
            for row in rows:
                document = clean_document({
                    "review_id": row["review_id"],
                    "order_id": row["order_id"],
                    "product_context": row["product_context"] or [],
                    "customer_context": {
                        "customer_id": row["customer_id"],
                        "state": row["customer_state"],
                    },
                    "review_score": row["review_score"],
                    "comment": {
                        "title": row["review_comment_title"],
                        "message": row["review_comment_message"],
                    },
                    "dates": {
                        "review_creation_date": row["review_creation_date"],
                        "review_answer_timestamp": row["review_answer_timestamp"],
                    },
                    "updated_at": SYNCED_AT,
                })
                operations.append(UpdateOne(
                    {"review_id": document["review_id"], "order_id": document["order_id"]},
                    {"$set": document},
                    upsert=True,
                ))
            total += bulk_upsert(collection, operations, "review_documents")
    return total


def main() -> None:
    """Ejecuta la sincronizacion completa de colecciones derivadas."""
    print("[sync] Iniciando sincronizacion PostgreSQL -> MongoDB")
    print(f"[sync] Base Mongo destino: {MONGO_DB_NAME}")

    with psycopg.connect(postgres_dsn()) as pg_conn:
        # El search_path se configura una sola vez para que las consultas usen el esquema ecommify.
        pg_conn.execute("SET search_path TO ecommify, public")
        mongo_client = MongoClient(mongo_uri())
        mongo_db = mongo_client[MONGO_DB_NAME]

        totals = {
            "product_catalog": sync_product_catalog(pg_conn, mongo_db),
            "customer_profiles": sync_customer_profiles(pg_conn, mongo_db),
            "seller_performance": sync_seller_performance(pg_conn, mongo_db),
            "geo_analytics": sync_geo_analytics(pg_conn, mongo_db),
            "review_documents": sync_review_documents(pg_conn, mongo_db),
        }

        print("[sync] Resumen final")
        for collection, count in totals.items():
            print(f"[sync] {collection}: {count} documentos procesados")

        mongo_client.close()


if __name__ == "__main__":
    main()
