-- 1. Витрина: ежедневные показатели только по состоявшимся заказам.
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_sales_kpi AS
WITH order_totals AS (
    SELECT o.order_id, o.customer_id, o.ordered_at::DATE AS order_date,
           SUM(oi.quantity * oi.unit_price) + MAX(o.delivery_fee) AS order_total
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status IN ('paid', 'shipped', 'completed')
    GROUP BY o.order_id, o.customer_id, o.ordered_at::DATE
)
SELECT order_date, COUNT(*) AS orders_count, COUNT(DISTINCT customer_id) AS buyers_count,
       SUM(order_total) AS revenue
FROM order_totals
GROUP BY order_date;

-- 2. Выручка, число заказов и средний чек по месяцам.
WITH order_totals AS (
 SELECT o.order_id, DATE_TRUNC('month', o.ordered_at)::DATE AS month,
        SUM(oi.quantity * oi.unit_price) + MAX(o.delivery_fee) AS total
 FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
 WHERE o.status IN ('paid', 'shipped', 'completed') GROUP BY o.order_id, 2
)
SELECT month, COUNT(*) AS orders, SUM(total) AS revenue, ROUND(AVG(total), 2) AS avg_order_value
FROM order_totals GROUP BY month ORDER BY month;

-- 3. Топ товаров по выручке.
SELECT p.product_name, SUM(oi.quantity) AS units, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'completed')
GROUP BY p.product_id, p.product_name ORDER BY revenue DESC;

-- 4. Категории: выручка, валовая прибыль и число проданных единиц.
SELECT c.category_name, SUM(oi.quantity) AS units,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       SUM(oi.quantity * (oi.unit_price - p.unit_cost)) AS gross_profit
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id JOIN orders o ON o.order_id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'completed') GROUP BY c.category_name ORDER BY gross_profit DESC;

-- 5. Клиенты, совершившие повторную покупку.
SELECT c.full_name, COUNT(*) AS completed_orders, MIN(o.ordered_at)::DATE AS first_order,
       MAX(o.ordered_at)::DATE AS last_order
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status IN ('paid', 'shipped', 'completed') GROUP BY c.customer_id, c.full_name HAVING COUNT(*) > 1;

-- 6. Доля повторных покупателей по месяцам.
WITH valid_orders AS (
 SELECT customer_id, ordered_at, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at) AS purchase_no
 FROM orders WHERE status IN ('paid', 'shipped', 'completed')
)
SELECT DATE_TRUNC('month', ordered_at)::DATE AS month, COUNT(DISTINCT customer_id) AS buyers,
       COUNT(DISTINCT customer_id) FILTER (WHERE purchase_no > 1) AS repeat_buyers
FROM valid_orders GROUP BY 1 ORDER BY 1;

-- 7. Ранжирование товаров внутри категории по выручке.
WITH product_revenue AS (
 SELECT c.category_name, p.product_name, SUM(oi.quantity * oi.unit_price) AS revenue
 FROM order_items oi JOIN products p ON p.product_id = oi.product_id
 JOIN categories c ON c.category_id = p.category_id JOIN orders o ON o.order_id = oi.order_id
 WHERE o.status IN ('paid', 'shipped', 'completed') GROUP BY 1, 2
)
SELECT *, DENSE_RANK() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS category_rank
FROM product_revenue;

-- 8. Товары без продаж в сентябре: сигнал для ассортимента.
SELECT p.product_name FROM products p WHERE NOT EXISTS (
 SELECT 1 FROM order_items oi JOIN orders o ON o.order_id = oi.order_id
 WHERE oi.product_id = p.product_id AND o.status IN ('paid', 'shipped', 'completed')
   AND o.ordered_at >= '2026-09-01' AND o.ordered_at < '2026-10-01'
);

-- 9. Заказы с возвратом и их стоимость.
SELECT o.order_id, c.full_name, SUM(oi.quantity * oi.unit_price) AS returned_value
FROM orders o JOIN customers c ON c.customer_id = o.customer_id JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'returned' GROUP BY o.order_id, c.full_name;

-- 10. Накопительная выручка.
WITH daily AS (
 SELECT o.ordered_at::DATE AS day, SUM(oi.quantity * oi.unit_price) AS revenue
 FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
 WHERE o.status IN ('paid', 'shipped', 'completed') GROUP BY 1
)
SELECT day, revenue, SUM(revenue) OVER (ORDER BY day) AS cumulative_revenue FROM daily;

-- 11. Первый заказ клиента: основа когортного анализа.
SELECT c.customer_id, c.full_name, MIN(o.ordered_at)::DATE AS first_purchase_date
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status IN ('paid', 'shipped', 'completed') GROUP BY c.customer_id, c.full_name;

-- 12. Когортное удержание по месяцу первой покупки.
WITH first_orders AS (
 SELECT customer_id, DATE_TRUNC('month', MIN(ordered_at)) AS cohort_month
 FROM orders WHERE status IN ('paid', 'shipped', 'completed') GROUP BY customer_id
), activity AS (
 SELECT f.cohort_month, DATE_TRUNC('month', o.ordered_at) AS activity_month, o.customer_id
 FROM first_orders f JOIN orders o ON o.customer_id = f.customer_id
 WHERE o.status IN ('paid', 'shipped', 'completed')
)
SELECT cohort_month::DATE, activity_month::DATE, COUNT(DISTINCT customer_id) AS active_customers
FROM activity GROUP BY 1, 2 ORDER BY 1, 2;

-- 13. Проверка данных: позиции заказа должны иметь положительную стоимость.
SELECT order_item_id, order_id FROM order_items WHERE quantity <= 0 OR unit_price <= 0;
