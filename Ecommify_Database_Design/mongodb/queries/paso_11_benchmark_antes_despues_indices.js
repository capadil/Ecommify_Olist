// Ecommify Database Design
// Paso 11: benchmark comparativo antes/despues para MongoDB.
//
// Objetivo:
//   Guardar evidencias cuantitativas en una coleccion, no solo imprimir
//   .explain() en consola. Esto permite construir tablas y graficos despues.
//
// Estrategia:
//   1. Baseline controlado: hint({ $natural: 1 }) fuerza recorrido natural.
//   2. Optimizado: hint(<indice>) fuerza el indice esperado.
//   3. Cada medicion se inserta en ecommify_analytics.benchmark_results.
//
// Ejecucion desde docker/:
//   docker compose exec mongo mongosh -u ecommify_admin -p ecommify_password --authenticationDatabase admin /workspace/mongodb/queries/paso_11_benchmark_antes_despues_indices.js

const targetDb = db.getSiblingDB("ecommify_analytics");
const runId = `mongo_${new Date().toISOString().replace(/[-:.TZ]/g, "")}`;
const results = targetDb.benchmark_results;

results.createIndex({ run_id: 1, engine: 1, benchmark_name: 1, scenario: 1 });

function collectExecutionStages(stage, stages) {
  if (!stage || typeof stage !== "object") {
    return;
  }
  if (stage.stage) {
    stages.push(stage.stage);
  }
  for (const key of Object.keys(stage)) {
    if (typeof stage[key] === "object") {
      collectExecutionStages(stage[key], stages);
    }
  }
}

function saveBenchmark(benchmarkName, scenario, queryLabel, expectedAccessPath, cursor) {
  const explainResult = cursor.explain("executionStats");
  const stats = explainResult.executionStats;
  const stages = [];
  collectExecutionStages(stats.executionStages, stages);

  const nReturned = stats.nReturned;
  const totalDocsExamined = stats.totalDocsExamined;
  const totalKeysExamined = stats.totalKeysExamined;
  const executionTimeMillis = stats.executionTimeMillis;
  const efficiencyRatio = totalDocsExamined === 0 ? null : nReturned / totalDocsExamined;

  results.insertOne({
    run_id: runId,
    engine: "MongoDB",
    benchmark_name: benchmarkName,
    scenario,
    query_label: queryLabel,
    expected_access_path: expectedAccessPath,
    n_returned: nReturned,
    total_docs_examined: totalDocsExamined,
    total_keys_examined: totalKeysExamined,
    execution_time_millis: executionTimeMillis,
    efficiency_ratio: efficiencyRatio,
    execution_stages: stages,
    explain_summary: {
      queryPlanner: explainResult.queryPlanner,
      executionStats: stats
    },
    created_at: new Date()
  });
}

saveBenchmark(
  "product_catalog category lookup",
  "baseline_natural_scan",
  "product_catalog_by_category",
  "Collection natural scan",
  targetDb.product_catalog.find(
    { "category.translated_name": "computers_accessories" },
    { product_id: 1, category: 1, sales_metrics: 1 }
  ).hint({ $natural: 1 }).limit(20)
);

saveBenchmark(
  "product_catalog category lookup",
  "optimized_with_index",
  "product_catalog_by_category",
  "category.translated_name_1",
  targetDb.product_catalog.find(
    { "category.translated_name": "computers_accessories" },
    { product_id: 1, category: 1, sales_metrics: 1 }
  ).hint({ "category.translated_name": 1 }).limit(20)
);

saveBenchmark(
  "customer_profiles state lookup",
  "baseline_natural_scan",
  "customer_profiles_by_state",
  "Collection natural scan",
  targetDb.customer_profiles.find(
    { "location.state": "SP" },
    { customer_id: 1, segment: 1, location: 1 }
  ).hint({ $natural: 1 }).limit(20)
);

saveBenchmark(
  "customer_profiles state lookup",
  "optimized_with_index",
  "customer_profiles_by_state",
  "location.state_1",
  targetDb.customer_profiles.find(
    { "location.state": "SP" },
    { customer_id: 1, segment: 1, location: 1 }
  ).hint({ "location.state": 1 }).limit(20)
);

saveBenchmark(
  "geo_analytics city lookup",
  "baseline_natural_scan",
  "geo_analytics_by_state_city",
  "Collection natural scan",
  targetDb.geo_analytics.find(
    { state: "SP", city: "sao paulo" },
    { geo_key: 1, state: 1, city: 1, sales_metrics: 1 }
  ).hint({ $natural: 1 }).limit(20)
);

saveBenchmark(
  "geo_analytics city lookup",
  "optimized_with_index",
  "geo_analytics_by_state_city",
  "state_1_city_1",
  targetDb.geo_analytics.find(
    { state: "SP", city: "sao paulo" },
    { geo_key: 1, state: 1, city: 1, sales_metrics: 1 }
  ).hint({ state: 1, city: 1 }).limit(20)
);

saveBenchmark(
  "review_documents low score lookup",
  "baseline_natural_scan",
  "review_documents_by_low_score",
  "Collection natural scan",
  targetDb.review_documents.find(
    { review_score: { $lte: 2 } },
    { review_id: 1, order_id: 1, review_score: 1 }
  ).hint({ $natural: 1 }).limit(20)
);

saveBenchmark(
  "review_documents low score lookup",
  "optimized_with_index",
  "review_documents_by_low_score",
  "review_score_1",
  targetDb.review_documents.find(
    { review_score: { $lte: 2 } },
    { review_id: 1, order_id: 1, review_score: 1 }
  ).hint({ review_score: 1 }).limit(20)
);
