/* Лабораторная работа 1. Простые запросы на выборку данных.
   *** Богдан *** гр. 9319**
   SQL: PosgresSQL */

-- 1. Выбрать список всех продуктов из первой категории (пиццы) по номеру категории .
SELECT *
FROM pd_products
WHERE category_id = 1;
-- 2. Выбрать все продукты, в описании которых упоминается “Моцарелла”. Выборка должна содержать только наименование и описание.
SELECT product_name,
    description
FROM pd_products
WHERE lower(description) LIKE '%моцарелла%';
-- 3.Список домов по улицам Красноармейская и Кирова.Выборка должна представлять список адресов в формате < название улицы >,
-- дом < номер дома > кв.< номер квартиры >.
SELECT street || ', дом ' || house_number || ' кв ' || apartment as список_домов
FROM pd_locations
WHERE lower(street) LIKE '%красноармейская%'
    OR lower(street) LIKE '%кирова%';
-- 4. Список всех острых или вегетарианских пицц с базиликом. Выборка должна содержать только наименование, описание, номер категории.
SELECT product_name,
    description,
    category_id
FROM pd_products
WHERE category_id = 1
    AND lower(description) LIKE '%базилик%'
    AND (
        hot = '1'
        OR vegan = '1'
    );
-- 5 Список курьеров в именах, которых (неважно в какой части) есть одна или две “а”, и фамилия оканчивается “ва”.
-- Для старших группы (ответственных) вывести  отметку с текстом “начальник”. 
-- Выборка должна содержать только один столбец: полное имя (фамилия, имя, отчество) и отметку.
-- Все столбец должн быть поименован.
SELECT CASE
        WHEN manager_id IS NOT null THEN name || ' ' || last_name || ' ' || patronymic
        ELSE name || ' ' || last_name || ' ' || patronymic || ' (начальник)'
    END
FROM pd_employees
WHERE post = 'Курьер'
    AND (
        (
            name LIKE '%а%'
            AND name NOT LIKE '%а%а%а%'
        )
        OR (
            last_name LIKE '%а%'
            AND last_name NOT LIKE '%а%а%а%'
        )
        OR (
            patronymic LIKE '%а%'
            AND patronymic NOT LIKE '%а%а%а%'
        )
    )
    AND last_name LIKE '%ва';
-- 6. Список всех острых пицц стоимостью от 460 до 510, если пицц  при этом ещё и вегетарианская, то стоимость может доходить до 560. 
-- Выборка должна содержать только наименование, цену и отметки об остроте и доступности для вегетарианцев. 
SELECT product_name,
    price,
    hot,
    vegan
FROM pd_products
WHERE category_id = 1
    AND (
        (
            price BETWEEN 460 AND 510
        )
        AND vegan = '0'
    )
    OR (
        (
            price BETWEEN 460 AND 560
        )
        AND VEGAN = '1'
    );
-- 7. Для каждого продукта рассчитать, на сколько процентов можно поднять цену,  
-- так что бы первая цифра цены не поменялась. Выборка должна содержать только наименование, цену, 
-- процент повышения цены до 3-х знаков после запятой, размер возможного повышения с учётом копеек
-- и размер возможного повышения в рублях. 
SELECT product_name AS наименование,
    price AS цена,
    round(
        (
            ((10 ^(floor(log(price)))) - 0.01) - price % (10 ^(floor(log(price))))
        ) / (price / (10 ^(floor(log(price))))),
        3
    ) AS процент_повышения,
    round(
        ((10 ^(floor(log(price)))) - 0.01) - price % (10 ^(floor(log(price)))),
        2
    ) AS повышение_с_копейками,
    floor(
        ((10 ^(floor(log(price)))) - 0.01) - price % (10 ^(floor(log(price))))
    ) AS повышение_в_рублях
FROM pd_products;
-- 8. Дополнительная наценка (процент наценки уже заложен в цену) для острых продуктов составляет - 1,5% ,
-- для вегетарианских - 1%, для острых и вегетарианских - 2%
-- . Выбрать продукты, для которых цена без наценки не превышает 500 для пицц, 180 для сэндвич-роллов 60 для остальных. 
-- Выборка должна содержать только наименование, описание, цену, цену без наценки (до 2-х знаков после запятой) 
-- и отметки об остроте и доступности для вегетарианцев. 
SELECT product_name,
    description,
    price,
    CASE
        WHEN hot = '1'
        AND vegan = '1' THEN round(price * 0.98, 2)
        WHEN hot = '1' THEN round(price * 0.985, 2)
        WHEN vegan = '1' THEN round(price * 0.99, 2)
        ELSE price
    END AS cost_price,
    hot,
    vegan
FROM pd_products
WHERE CASE
        WHEN hot = '1'
        AND vegan = '1' THEN round(price * 0.98, 2)
        WHEN hot = '1' THEN round(price * 0.985, 2)
        WHEN vegan = '1' THEN round(price * 0.99, 2)
        ELSE price
    END <= CASE
        WHEN category_id = 1 THEN 500
        WHEN category_id = 4 THEN 180
        ELSE 60
    END;
-- 9. Список всех продуктов с их типами и описанием. Выборка должна содержать только тип (наименование типа), 
-- название продукта и его описание. 
SELECT c.category_name,
    p.product_name,
    p.description
FROM pd_products p
    INNER JOIN pd_categories c ON p.category_id = c.category_id;
-- 10. Список всех продуктов, которых в одном заказе хотя бы раз было более 9 штук. Выборка должна содержать только наименование и цену. 
SELECT DISTINCT product_name,
    price
FROM pd_products ps
    INNER JOIN pd_order_details o_d ON ps.product_id = o_d.product_id
WHERE o_d.quantity > 9;
-- 11. Список всех заказчиков, заказывавших пиццу в октябрьском районе в сентябре или октябре. Выборка должна содержать только полные имена одной стройкой.   
SELECT DISTINCT name || ' ' || last_name || ' ' || patronymic
FROM pd_customers c
    INNER JOIN pd_orders o ON o.cust_id = c.cust_id
    INNER JOIN pd_locations l ON o.location_id = l.location_id
WHERE EXTRACT(
        MONTH
        FROM o.order_date
    ) IN (9, 10)
    AND l.area = 'Октябрьский'
    AND o.order_state != 'CANCEL';
-- 12. Список имён все страдников и с указанием имени начальника. Для начальников в соотв. Столбце выводить – ‘шеф’. 
SELECT e1.name,
    CASE
        WHEN e1.manager_id IS null THEN 'шеф'
        ELSE (
            SELECT name
            FROM pd_employees e2
            WHERE e1.manager_id = e2.emp_id
        )
    END
FROM pd_employees e1;
-- 13. Список всех заказов, которые были доставлены под руководствам Баранова (или им самим). 
-- В списке также должны отображаться: номер заказа, имя курьера и район (‘нет’ – если район не известен).
SELECT order_id AS номер_заказа,
    e.name,
    CASE
        WHEN l.area IS NOT null THEN l.area
        ELSE 'нет'
    END AS area
FROM (
        SELECT emp_id,
            name
        FROM pd_employees
        where manager_id = (
                select emp_id
                from pd_employees
                where lower(last_name) LIKE 'баранов%'
            )
            OR emp_id = (
                select emp_id
                from pd_employees
                where lower(last_name) LIKE 'баранов%'
            )
    ) e
    INNER JOIN pd_orders o ON e.emp_id = o.emp_id
    INNER JOIN pd_locations l ON o.location_id = l.location_id;
-- 14. Список продуктов с типом, которые заказывали вмести с острыми или вегетарианскими пиццами в этом месяце.
SELECT p1.product_name,
    c.category_name
FROM (
        SELECT DISTINCT od1.product_id
        FROM ( -- отбираем айдишники заказов, в которых присутствовали острые/веганские пиццы
                SELECT od.order_id
                FROM pd_order_details od
                    INNER JOIN pd_products p ON p.product_id = od.product_id
                    INNER JOIN pd_orders o ON o.order_id = od.order_id
                WHERE p.category_id = 1
                    AND (
                        p.hot = '1'
                        OR p.vegan = '1'
                    )
                    AND (
                        EXTRACT(
                            MONTH
                            FROM o.order_date
                        ) = EXTRACT(
                            MONTH
                            FROM current_date
                        )
                        AND EXTRACT(
                            YEAR
                            FROM o.order_date
                        ) = EXTRACT(
                            YEAR
                            FROM current_date
                        )
                    )
            ) o_ids
            -- оставляем детали только о заказах с нужными id, это переходит в from clause для subquery где мы выбираем уникальные продукты из этих заказов
            INNER JOIN pd_order_details od1 ON o_ids.order_id = od1.order_id
    ) p_ids 
    -- получили айди всех продуктов, которые заказывали с острой/веган пиццами в этом месяце. 
    -- Соединяем с таблицей товаров чтобы вытащить оттуда имя и с таблицей категорий чтобы вытащить название категории
    INNER JOIN pd_products p1 ON p_ids.product_id = p1.product_id
    INNER JOIN pd_categories c ON p1.category_id = c.category_id;
