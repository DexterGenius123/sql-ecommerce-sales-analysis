INSERT INTO customers (full_name, email, registered_at, city) VALUES
('Арман Сериков', 'arman@example.test', '2026-06-10', 'Алматы'),
('Айша Омарова', 'aisha@example.test', '2026-06-15', 'Астана'),
('Руслан Ким', 'ruslan@example.test', '2026-07-01', 'Алматы'),
('Елена Иванова', 'elena@example.test', '2026-07-12', 'Шымкент'),
('Дамир Беков', 'damir@example.test', '2026-08-03', 'Алматы'),
('София Алиева', 'sofia@example.test', '2026-08-20', 'Караганда');

INSERT INTO categories (category_name) VALUES ('Электроника'), ('Дом'), ('Спорт');
INSERT INTO products (category_id, product_name, unit_price, unit_cost) VALUES
(1, 'Беспроводные наушники', 18500, 10500), (1, 'Клавиатура', 12900, 7200),
(2, 'Термокружка', 6500, 2800), (2, 'Настольная лампа', 15900, 8500),
(3, 'Коврик для йоги', 9900, 4700), (3, 'Бутылка для воды', 4200, 1600);

INSERT INTO orders (customer_id, ordered_at, status, delivery_fee) VALUES
(1, '2026-07-03 06:00+00', 'completed', 1000), (2, '2026-07-09 08:00+00', 'completed', 0),
(3, '2026-07-20 05:00+00', 'returned', 1000), (1, '2026-08-02 07:00+00', 'completed', 1000),
(4, '2026-08-15 09:00+00', 'completed', 0), (2, '2026-08-28 04:00+00', 'cancelled', 1000),
(5, '2026-09-04 06:00+00', 'shipped', 1000), (1, '2026-09-12 08:00+00', 'completed', 0),
(6, '2026-09-18 05:00+00', 'completed', 1000), (4, '2026-09-22 10:00+00', 'completed', 0);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 18500), (1, 6, 1, 4200), (2, 3, 2, 6500), (3, 2, 1, 12900),
(4, 5, 1, 9900), (4, 6, 2, 4200), (5, 4, 1, 15900), (5, 3, 1, 6500),
(6, 1, 1, 18500), (7, 1, 1, 18500), (7, 3, 1, 6500), (8, 2, 1, 12900),
(8, 6, 1, 4200), (9, 5, 2, 9900), (10, 4, 1, 15900), (10, 3, 1, 6500);
