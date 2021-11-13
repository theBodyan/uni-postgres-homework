/* Лабораторная работа 3. Запросы с группировкой и представления.
   *** Богдан *** гр. 9319**
   SQL: PosgresSQL */

-- РАБОТА ВЫПОЛНЕНА ОПИРАЯСЬ НА СТРУКТУРНЫЕ ИЗМЕНЕНИЯ, ПРИМЕНЕННЫЕ ВО ВТОРОЙ ЛАБОРАТОРНОЙ.

-- 1. Найти среднюю стоимость пиццы с точность до второго знака
SELECT ROUND(AVG(price), 2)
FROM pd_products
    INNER JOIN pd_categories ON pd_products.category_id = pd_categories.category_id
WHERE lower(pd_categories.category_name) LIKE '%пицца%';
-- 2. Найти среднюю стоимость для каждой категории товара с точность до второго знака. 
-- Выборка должна содержать наименование категории и среднюю стоимость.
SELECT MAX(cats.category_name),
    ROUND(AVG(price), 2)
FROM pd_products prods
    INNER JOIN pd_categories cats ON prods.category_id = cats.category_id
GROUP BY cats.category_name;
-- 3. Для каждой из должностей найдите средний, максимальный и минимальный возраст сотрудников. 
-- Выборка должна название должности и средний, максимальный и минимальный возраст, все столбцы должны быть подписаны.
SELECT MAX(p.post) vacancy,
    FLOOR(
        AVG(
            DATE_PART('year', NOW()) - DATE_PART('year', e.birthday)
        )
    ) avg_age,
    MIN(
        DATE_PART('year', NOW()) - DATE_PART('year', e.birthday)
    ) min_age,
    MAX(
        DATE_PART('year', NOW()) - DATE_PART('year', e.birthday)
    ) max_age
FROM pd_employees e
    INNER JOIN pd_employee_post intermediary ON e.emp_id = intermediary.employee_id
    INNER JOIN pd_posts p ON p.post_id = intermediary.post_id
GROUP BY p.post;
-- 4. Для каждого заказа посчитать сумму заказа. Выборка должна содержать номер заказа, сумму.
SELECT MAX(order_id::TEXT) order_number,
    SUM(p.price * o_d.quantity) order_total
FROM pd_order_details o_d
    INNER JOIN pd_products p ON o_d.product_id = p.product_id
GROUP BY o_d.order_id;
-- 5. Напишите запрос, выводящий следующие данные: номер заказа, имя курьера (одной строкой), 
-- имя заказчика (одной строкой), обща стоимость заказа, строк доставки, отметка о том был ли заказа доставлен вовремя.
SELECT o.order_id,
    CASE
        WHEN e.emp_id IS NOT NULL THEN e.name || ' ' || e.last_name || ' ' || e.patronymic
        ELSE 'не назначен'
    END employee,
    c.name || ' ' || c.last_name || ' ' || c.patronymic customer,
    o_p.total,
    CASE
        WHEN o.exec_date IS NOT NULL THEN o.exec_date
        ELSE null
    END exec_date,
    CASE
        WHEN exec_date IS NULL THEN 'не доставлен'
        WHEN exec_date > delivery_date THEN 'с опозданием'
        ELSE 'вовремя'
    END delivery_status
FROM pd_orders o
    INNER JOIN (
        SELECT MAX(order_id) order_id,
            ROUND(SUM(p.price * o_d.quantity), 2) total
        FROM pd_order_details o_d
            LEFT JOIN pd_products p ON o_d.product_id = p.product_id
        GROUP BY o_d.order_id
    ) o_p ON o.order_id = o_p.order_id
    LEFT JOIN pd_employees e ON o.emp_id = e.emp_id
    INNER JOIN pd_customers c ON o.cust_id = c.cust_id;
-- ЛИБО ИСКЛЮЧАЯ НЕДОСТАВЛЕННЫЕ ЗАКАЗЫ:
SELECT o.order_id,
    e.name || ' ' || e.last_name || ' ' || e.patronymic employee,
    c.name || ' ' || c.last_name || ' ' || c.patronymic customer,
    o_p.total,
    o.exec_date,
    CASE
        WHEN exec_date IS NULL THEN 'не доставлен'
        WHEN exec_date > delivery_date THEN 'с опозданием'
        ELSE 'вовремя'
    END delivery_status
FROM pd_orders o
    INNER JOIN (
        SELECT MAX(order_id) order_id,
            ROUND(SUM(p.price * o_d.quantity), 2) total
        FROM pd_order_details o_d
            LEFT JOIN pd_products p ON o_d.product_id = p.product_id
        GROUP BY o_d.order_id
    ) o_p ON o.order_id = o_p.order_id
    INNER JOIN pd_employees e ON o.emp_id = e.emp_id
    INNER JOIN pd_customers c ON o.cust_id = c.cust_id;
-- 6. Напишите запрос, выводящий следующие данные для каждого месяца: общее количество заказов, 
-- процент доставленных заказов, процент отменённых заказов, общий доход за месяц 
-- (заказы в доставке и отменённые не учитываются, на задержанные заказы предоставляется скидка в размере 15%).
SELECT MAX(
        EXTRACT(
            YEAR
            FROM o.order_date
        )::TEXT
    ) AS YEAR,
    TO_CHAR(
        TO_DATE(
            EXTRACT(
                MONTH
                FROM o.order_date
            )::TEXT,
            'MM'
        ),
        'Month'
    ),
    COUNT(o.order_id) total_orders,
    100 *(
        COUNT(o.order_id) FILTER (
            WHERE LOWER(o.order_state) LIKE '%end%'
        )
    ) / COUNT(o.order_id) || '%' finished_orders,
    100 *(
        COUNT(o.order_id) FILTER (
            WHERE LOWER(o.order_state) LIKE '%cancel%'
        )
    ) / COUNT(o.order_id) || '%' cancelled_orders,
    ROUND(
        SUM(p.price * o_d.quantity) FILTER (
            WHERE (LOWER(o.order_state) LIKE '%end%')
                AND (o.exec_date <= o.delivery_date)
        ) + SUM(p.price * o_d.quantity * 0.85) FILTER (
            WHERE (LOWER(o.order_state) LIKE '%end%')
                AND (o.exec_date > o.delivery_date)
        ),
        2
    ) revenue
FROM pd_orders o
    INNER JOIN pd_order_details o_d ON o.order_id = o_d.order_id
    INNER JOIN pd_products p ON p.product_id = o_d.product_id
GROUP BY EXTRACT(
        MONTH
        FROM order_date
    );
-- 7. Для каждого заказа посчитать сумму, количество видов заказанных товаров, общее число позиций. 
-- Вывести только заказы, сделанные в августе или сентябре и на сумму более 5000.
SELECT SUM(o_d.quantity * p.price) order_total,
    COUNT(DISTINCT o_d.product_id) distinct_products,
    SUM(o_d.quantity) total_quantity_of_products
FROM pd_order_details o_d
    INNER JOIN pd_products p ON o_d.product_id = p.product_id
    INNER JOIN pd_orders o ON o_d.order_id = o.order_id
WHERE EXTRACT(
        MONTH
        FROM o.delivery_date
    ) IN (8, 9)
GROUP BY o_d.order_id
HAVING SUM(o_d.quantity * p.price) > 5000;
--ЛИБО ЕСЛИ ПОД ВИДАМИ ПОДРАЗУМЕВАЮТСЯ КАТЕГОРИИ
SELECT SUM(o_d.quantity * p.price) order_total,
    COUNT(DISTINCT p.category_id) distinct_categories,
    SUM(o_d.quantity) total_quantity_of_products
FROM pd_order_details o_d
    INNER JOIN pd_products p ON o_d.product_id = p.product_id
    INNER JOIN pd_orders o ON o_d.order_id = o.order_id
WHERE EXTRACT(
        MONTH
        FROM o.delivery_date
    ) IN (8, 9)
GROUP BY o_d.order_id
HAVING SUM(o_d.quantity * p.price) > 5000;
-- 8. Найти всех заказчиков, которые сделали заказ одного товара на сумму не менее 3000.
--  Отчёт должен содержать имя заказчика, номер заказа и стоимость.
SELECT MAX(name || ' ' || last_name || ' ' || patronymic) full_name,
    MAX(o_d.order_id::TEXT) order_id,
    ROUND(SUM(p.price * o_d.quantity), 2) total
FROM pd_order_details o_d
    INNER JOIN pd_orders o ON o_d.order_id = o.order_id
    INNER JOIN pd_products p ON o_d.product_id = p.product_id
    INNER JOIN pd_customers c ON o.cust_id = c.cust_id
WHERE p.price * o_d.quantity >= 3000
GROUP BY o_d.order_id;
-- 9. Список продуктов с типом, которые заказывали вмести с острыми или вегетарианскими пиццами летом.
SELECT DISTINCT c.category_name,
    p.product_name
FROM pd_order_details o_d
    INNER JOIN (
        SELECT o.order_id o_id
        FROM pd_products p
            INNER JOIN pd_categories c ON (p.category_id = c.category_id)
            AND (LOWER(c.category_name) LIKE '%пицц%')
            AND (
                p.hot = '1'
                OR p.vegan = '1'
            )
            INNER JOIN pd_order_details o_d ON (o_d.product_id = p.product_id)
            INNER JOIN pd_orders o ON (o.order_id = o_d.order_id)
            AND (
                EXTRACT(
                    MONTH
                    FROM o.delivery_date
                ) IN (6, 7, 8)
            )
    ) o_ids ON (o_d.order_id = o_ids.o_id)
    INNER JOIN pd_products p ON (o_d.product_id = p.product_id)
    INNER JOIN pd_categories c ON (p.category_id = c.category_id);
-- 10. Для каждого заказа, в котором есть хотя бы 1 острая пицца посчитать стоимость напитков.
WITH drinks_ids AS (
    (
        SELECT product_id
        FROM pd_products p
            INNER JOIN pd_categories c ON (p.category_id = c.category_id)
            AND (LOWER(c.category_name) LIKE '%напит%')
    )
),
orders_with_hot_pizza AS (
    (
        SELECT order_id
        FROM pd_categories c
            INNER JOIN pd_products p ON (c.category_id = p.category_id)
            AND (LOWER(c.category_name) LIKE '%пицц%')
            AND (p.hot = '1')
            INNER JOIN pd_order_details o_d ON (o_d.product_id = p.product_id)
    )
)
SELECT CASE
        WHEN MAX(p.product_id::TEXT)::INT IN (
            SELECT product_id
            FROM drinks_ids
        ) THEN ROUND(
            SUM(o_d.quantity * p.price) FILTER (
                WHERE (
                        p.product_id IN (
                            SELECT product_id
                            FROM drinks_ids
                        )
                    )
            ),
            2
        )
        ELSE 0
    END drinks_cost
FROM pd_order_details o_d
    INNER JOIN orders_with_hot_pizza o_ids ON (o_d.order_id = o_ids.order_id)
    INNER JOIN pd_products p ON (p.product_id = o_d.product_id)
GROUP BY o_d.order_id;
-- 11. Найти курьера выполнившего вовремя наибольшее число заказов.
WITH courier_orders_on_time AS (
    SELECT MAX(
            e.name || ' ' || e.last_name || ' ' || e.patronymic
        ) AS courier_name,
        COUNT(o.exec_date) FILTER (
            WHERE (o.exec_date IS NOT NULL)
                AND (o.exec_date <= o.delivery_date)
        ) orders_on_time
    FROM pd_orders o
        INNER JOIN pd_employees e ON (e.emp_id = o.emp_id)
    GROUP BY e.emp_id
)
SELECT courier_name
FROM courier_orders_on_time
WHERE orders_on_time = (
        SELECT MAX(orders_on_time)
        FROM courier_orders_on_time
    );
-- 12. Для каждого месяца найти стоимость самого дорогого заказа.
WITH order_price AS (
    SELECT MAX(order_id::TEXT)::INT order_id,
        SUM(p.price * o_d.quantity) order_total
    FROM pd_order_details o_d
        INNER JOIN pd_products p ON o_d.product_id = p.product_id
    GROUP BY o_d.order_id
),
orders_with_dates_and_prices AS (
    SELECT o.delivery_date,
        o_p.order_total
    FROM order_price o_p
        INNER JOIN pd_orders o ON o_p.order_id = o.order_id
)
SELECT MAX(
        EXTRACT(
            YEAR
            FROM delivery_date
        )::TEXT
    ) AS YEAR,
    TO_CHAR(
        TO_DATE(
            EXTRACT(
                MONTH
                FROM delivery_date
            )::TEXT,
            'MM'
        ),
        'Month'
    ),
    MAX(order_total)
FROM orders_with_dates_and_prices
GROUP BY EXTRACT(
        MONTH
        FROM delivery_date
    );
-- 13. Оформить запросы 6-8, как представления.
CREATE view query_6 AS (
    SELECT MAX(
            EXTRACT(
                YEAR
                FROM o.order_date
            )::TEXT
        ) AS YEAR,
        TO_CHAR(
            TO_DATE(
                EXTRACT(
                    MONTH
                    FROM o.order_date
                )::TEXT,
                'MM'
            ),
            'Month'
        ),
        COUNT(o.order_id) total_orders,
        100 *(
            COUNT(o.order_id) FILTER (
                WHERE LOWER(o.order_state) LIKE '%end%'
            )
        ) / COUNT(o.order_id) || '%' finished_orders,
        100 *(
            COUNT(o.order_id) FILTER (
                WHERE LOWER(o.order_state) LIKE '%cancel%'
            )
        ) / COUNT(o.order_id) || '%' cancelled_orders,
        ROUND(
            SUM(p.price * o_d.quantity) FILTER (
                WHERE (LOWER(o.order_state) LIKE '%end%')
                    AND (o.exec_date <= o.delivery_date)
            ) + SUM(p.price * o_d.quantity * 0.85) FILTER (
                WHERE (LOWER(o.order_state) LIKE '%end%')
                    AND (o.exec_date > o.delivery_date)
            ),
            2
        ) revenue
    FROM pd_orders o
        INNER JOIN pd_order_details o_d ON o.order_id = o_d.order_id
        INNER JOIN pd_products p ON p.product_id = o_d.product_id
    GROUP BY EXTRACT(
            MONTH
            FROM order_date
        )
); 
CREATE view query_7 AS (
    SELECT SUM(o_d.quantity * p.price) order_total,
        COUNT(DISTINCT o_d.product_id) distinct_products,
        SUM(o_d.quantity) total_quantity_of_products
    FROM pd_order_details o_d
        INNER JOIN pd_products p ON o_d.product_id = p.product_id
        INNER JOIN pd_orders o ON o_d.order_id = o.order_id
    WHERE EXTRACT(
            MONTH
            FROM o.delivery_date
        ) IN (8, 9)
    GROUP BY o_d.order_id
    HAVING SUM(o_d.quantity * p.price) > 5000
);
CREATE view query_8 AS (
    SELECT MAX(name || ' ' || last_name || ' ' || patronymic) full_name,
        MAX(o_d.order_id::TEXT) order_id,
        ROUND(SUM(p.price * o_d.quantity), 2) total
    FROM pd_order_details o_d
        INNER JOIN pd_orders o ON o_d.order_id = o.order_id
        INNER JOIN pd_products p ON o_d.product_id = p.product_id
        INNER JOIN pd_customers c ON o.cust_id = c.cust_id
    WHERE p.price * o_d.quantity >= 3000
    GROUP BY o_d.order_id
);