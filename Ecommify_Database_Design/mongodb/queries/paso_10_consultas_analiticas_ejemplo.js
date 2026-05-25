// Ecommify Database Design
// Paso 10: consultas de ejemplo para colecciones analiticas derivadas.

const targetDb = db.getSiblingDB("ecommify_analytics");

// Catalogo de productos por categoria traducida.
targetDb.product_catalog.find(
  { "category.translated_name": "computers_accessories" },
  { product_id: 1, category: 1, dimensions: 1, review_summary: 1, sales_metrics: 1 }
).limit(20);

// Clientes principales por valor total pagado.
targetDb.customer_profiles.find(
  {},
  { customer_id: 1, segment: 1, order_metrics: 1, payment_summary: 1 }
).sort({ "payment_summary.total_payment_value": -1 }).limit(20);

// Desempeno de vendedores por estado.
targetDb.seller_performance.find(
  { "location.state": "SP" },
  { seller_id: 1, location: 1, monthly_metrics: 1, review_summary: 1 }
).limit(20);

// Dashboard de analitica geografica.
targetDb.geo_analytics.find(
  { state: "SP" },
  { geo_key: 1, state: 1, city: 1, sales_metrics: 1 }
).sort({ "sales_metrics.total_payment_value": -1 }).limit(20);

// Documentos de resenas con calificacion baja.
targetDb.review_documents.find(
  { review_score: { $lte: 2 } },
  { review_id: 1, order_id: 1, review_score: 1, comment: 1, product_context: 1 }
).limit(20);

