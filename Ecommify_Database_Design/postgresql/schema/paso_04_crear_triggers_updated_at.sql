-- Ecommify Database Design
-- Paso 04: crear funcion y triggers para mantener updated_at.

SET search_path TO ecommify, public;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_category_translation_updated_at ON category_translation;
CREATE TRIGGER trg_category_translation_updated_at
BEFORE UPDATE ON category_translation
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_customers_updated_at ON customers;
CREATE TRIGGER trg_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_sellers_updated_at ON sellers;
CREATE TRIGGER trg_sellers_updated_at
BEFORE UPDATE ON sellers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_order_items_updated_at ON order_items;
CREATE TRIGGER trg_order_items_updated_at
BEFORE UPDATE ON order_items
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_order_payments_updated_at ON order_payments;
CREATE TRIGGER trg_order_payments_updated_at
BEFORE UPDATE ON order_payments
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_order_reviews_updated_at ON order_reviews;
CREATE TRIGGER trg_order_reviews_updated_at
BEFORE UPDATE ON order_reviews
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_geolocation_clean_updated_at ON geolocation_clean;
CREATE TRIGGER trg_geolocation_clean_updated_at
BEFORE UPDATE ON geolocation_clean
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

