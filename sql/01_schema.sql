DROP TABLE IF EXISTS order_items, orders, products, categories, customers CASCADE;

CREATE TABLE customers (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    registered_at DATE NOT NULL,
    city TEXT NOT NULL
);

CREATE TABLE categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    product_name TEXT NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    unit_cost NUMERIC(12,2) NOT NULL CHECK (unit_cost >= 0 AND unit_cost <= unit_price),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    ordered_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('paid', 'shipped', 'completed', 'cancelled', 'returned')),
    delivery_fee NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0)
);

CREATE TABLE order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    UNIQUE (order_id, product_id)
);

CREATE INDEX idx_orders_customer_date ON orders (customer_id, ordered_at);
CREATE INDEX idx_orders_status_date ON orders (status, ordered_at);
CREATE INDEX idx_items_product ON order_items (product_id);
