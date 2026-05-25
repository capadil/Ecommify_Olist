// Ecommify Database Design
// Paso 09: crear colecciones y validadores de MongoDB.
// MongoDB no es la fuente de verdad. Almacena documentos derivados desde PostgreSQL.
// Usar solo tipos documentales de MongoDB. No declarar JSONB en MongoDB.

const dbName = "ecommify_analytics";
const targetDb = db.getSiblingDB(dbName);

function createOrUpdateCollection(name, validator) {
  const exists = targetDb.getCollectionNames().includes(name);
  if (!exists) {
    targetDb.createCollection(name, { validator });
  } else {
    targetDb.runCommand({ collMod: name, validator });
  }
}

createOrUpdateCollection("product_catalog", {
  $jsonSchema: {
    bsonType: "object",
    required: ["product_id", "updated_at"],
    properties: {
      product_id: { bsonType: "string" },
      category: {
        bsonType: "object",
        properties: {
          name: { bsonType: ["string", "null"] },
          translated_name: { bsonType: ["string", "null"] }
        }
      },
      dimensions: {
        bsonType: "object",
        properties: {
          weight_g: { bsonType: ["int", "long", "double", "null"] },
          length_cm: { bsonType: ["int", "long", "double", "null"] },
          height_cm: { bsonType: ["int", "long", "double", "null"] },
          width_cm: { bsonType: ["int", "long", "double", "null"] }
        }
      },
      specifications: { bsonType: "object" },
      photos: { bsonType: "array", items: { bsonType: "string" } },
      sales_metrics: { bsonType: "object" },
      review_summary: { bsonType: "object" },
      updated_at: { bsonType: "date" }
    }
  }
});

targetDb.product_catalog.createIndex({ product_id: 1 }, { unique: true });
targetDb.product_catalog.createIndex({ "category.translated_name": 1 });

createOrUpdateCollection("customer_profiles", {
  $jsonSchema: {
    bsonType: "object",
    required: ["customer_id", "updated_at"],
    properties: {
      customer_id: { bsonType: "string" },
      customer_unique_id: { bsonType: ["string", "null"] },
      location: { bsonType: "object" },
      order_metrics: { bsonType: "object" },
      payment_summary: { bsonType: "object" },
      review_summary: { bsonType: "object" },
      segment: { bsonType: ["string", "null"] },
      updated_at: { bsonType: "date" }
    }
  }
});

targetDb.customer_profiles.createIndex({ customer_id: 1 }, { unique: true });
targetDb.customer_profiles.createIndex({ segment: 1 });
targetDb.customer_profiles.createIndex({ "location.state": 1 });

createOrUpdateCollection("seller_performance", {
  $jsonSchema: {
    bsonType: "object",
    required: ["seller_id", "updated_at"],
    properties: {
      seller_id: { bsonType: "string" },
      location: { bsonType: "object" },
      monthly_metrics: { bsonType: "array", items: { bsonType: "object" } },
      review_summary: { bsonType: "object" },
      updated_at: { bsonType: "date" }
    }
  }
});

targetDb.seller_performance.createIndex({ seller_id: 1 }, { unique: true });
targetDb.seller_performance.createIndex({ "location.state": 1 });

createOrUpdateCollection("geo_analytics", {
  $jsonSchema: {
    bsonType: "object",
    required: ["geo_key", "updated_at"],
    properties: {
      geo_key: { bsonType: "string" },
      state: { bsonType: ["string", "null"] },
      city: { bsonType: ["string", "null"] },
      sales_metrics: { bsonType: "object" },
      customer_metrics: { bsonType: "object" },
      seller_metrics: { bsonType: "object" },
      updated_at: { bsonType: "date" }
    }
  }
});

targetDb.geo_analytics.createIndex({ geo_key: 1 }, { unique: true });
targetDb.geo_analytics.createIndex({ state: 1, city: 1 });

createOrUpdateCollection("review_documents", {
  $jsonSchema: {
    bsonType: "object",
    required: ["review_id", "order_id", "review_score", "updated_at"],
    properties: {
      review_id: { bsonType: "string" },
      order_id: { bsonType: "string" },
      product_context: { bsonType: "array", items: { bsonType: "object" } },
      customer_context: { bsonType: "object" },
      review_score: { bsonType: "int", minimum: 1, maximum: 5 },
      comment: {
        bsonType: "object",
        properties: {
          title: { bsonType: ["string", "null"] },
          message: { bsonType: ["string", "null"] }
        }
      },
      dates: { bsonType: "object" },
      updated_at: { bsonType: "date" }
    }
  }
});

targetDb.review_documents.createIndex({ review_id: 1 }, { unique: true });
targetDb.review_documents.createIndex({ order_id: 1 });
targetDb.review_documents.createIndex({ review_score: 1 });

