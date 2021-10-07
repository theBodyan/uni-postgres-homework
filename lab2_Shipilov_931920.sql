/* Лабораторная работа 2. Создание/Модификация/Удаление таблиц и данных.
   *** Богдан *** гр. 931920 
   SQL: PosgresSQL */

-- 1. Увеличить стоимость всех десертов на 5%, новая цена не должна содержать копеек (копейки отбросить, а не округлить)
UPDATE pd_products
SET price = cast(price * 1.05 AS integer)
WHERE category_id = (
        SELECT category_id
        FROM pd_categories
        WHERE lower(category_name) LIKE 'десерт%'
    )
RETURNING price;
-- 2. Для всех заказов, для которых указано время исполнения заказа (EXEC_DATE) выставить статус “ доставлен” (“END”)
UPDATE pd_orders
SET order_state = 'END'
WHERE (
        exec_date IS NOT null
        AND (
            order_state != 'END'
            OR order_state IS null
        )
    )
RETURNING order_state;
-- 3. Модифицировать схему базы данных так, что бы для каждого сотрудника 
-- можно было хранить несколько телефонных номеров и комментарий для каждого номера. 
-- Заполните новую таблицу/таблицы и удалите лишние столбцы.
CREATE TABLE pd_employee_phone_number (
    phone_id SERIAL PRIMARY KEY,
    phone varchar(100),
    details varchar(256),
    emp_id integer REFERENCES pd_employees (emp_id)
);
INSERT INTO pd_employee_phone_number (phone, emp_id)
SELECT phone,
    emp_id
FROM pd_employees;
ALTER TABLE pd_employees DROP COLUMN phone;
-- 4. Модифицировать схему базы данных так, что бы должности сотрудников 
-- хранились в отдельной таблице, и не осталось избыточных данных.
-- сделал отношение M-N на случай, если работник работает больше чем на одну ставку. Не знал, нужно ли считать это должностью менеджера,
-- когда работник является чьим-то менеджером. Решил, что это просто наставничество и не стал.
CREATE TABLE pd_posts (
    post_id SERIAL PRIMARY KEY,
    post varchar(100)
);
CREATE TABLE pd_employee_post (
    id SERIAL PRIMARY KEY,
    post_id integer REFERENCES pd_posts (post_id),
    employee_id integer REFERENCES pd_employees (emp_id)
);
INSERT INTO pd_posts (post)
SELECT DISTINCT post
FROM pd_employees;
INSERT INTO pd_employee_post (post_id, employee_id)
SELECT p.post_id,
    e.emp_id
FROM pd_employees e
    INNER JOIN pd_posts p ON e.post = p.post;
ALTER TABLE pd_employees DROP COLUMN post;
-- 5. Модифицировать схему базы данных так,
-- чтобы наименования районов хранились в отдельной таблице, и не осталось избыточных данных.
CREATE TABLE pd_areas(
    area_id SERIAL PRIMARY KEY,
    area_name varchar(100)
);
INSERT INTO pd_areas (area_name)
SELECT DISTINCT area
FROM pd_locations
WHERE area IS NOT null;
ALTER TABLE pd_locations
    RENAME COLUMN area TO area_id;
UPDATE pd_locations l
SET area_id = (
        SELECT area_id
        FROM pd_areas a
        WHERE l.area_id = a.area_name
    );
-- 6. Модифицировать схему базы данных таким образом, чтобы при удалении заказа удалялись все его позиции. 
-- Удалите все записи об отменённых заказах.
ALTER TABLE pd_order_details
ADD CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES pd_orders (order_id) ON DELETE CASCADE;
DELETE FROM pd_orders
WHERE order_state = 'CANCEL';
-- 7. Добавьте ограничение целостности, гарантирующие исполнение условия: все продукты в заказе должны содержаться в базе.
ALTER TABLE pd_order_details
ADD CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES pd_products (product_id);
-- 8. Добавьте ограничение целостности, гарантирующие исполнение условия: 
-- начальником может быть только реально существующий сотрудник.
ALTER TABLE pd_employees ADD CONSTRAINT manager_is_an_employee FOREIGN KEY (manager_id) REFERENCES pd_employees (emp_id)
-- 9. Добавьте ограничения целостности, гарантирующие следующих исполнение условия: 
-- наименования категории, наименования продуктов, имена сотрудников, имена заказчиков, 
-- названия районов, названия улиц, номера домов не могут быть пустыми.
ALTER TABLE pd_categories ALTER COLUMN category_name SET NOT NULL;
ALTER TABLE pd_products ALTER COLUMN product_name SET NOT NULL;
ALTER TABLE pd_customers ALTER COLUMN name SET NOT NULL; -- О полном имени не говорится, ставлю ограничение только на имя.
ALTER TABLE pd_areas ALTER COLUMN area_name SET NOT NULL;
ALTER TABLE pd_locations ALTER COLUMN street SET NOT NULL;
ALTER TABLE pd_locations ALTER COLUMN house_number SET NOT NULL;

-- В задании не говорилось не null, речь шла о пустоте. Поэтому исключаем пустые строки: 
ALTER TABLE pd_categories ADD CONSTRAINT category_name_is_not_empty CHECK(char_length(category_name) > 0);
ALTER TABLE pd_products ADD CONSTRAINT product_name_is_not_empty CHECK(char_length(product_name) > 0);
ALTER TABLE pd_customers ADD CONSTRAINT name_is_not_empty CHECK(char_length(name) > 0);
ALTER TABLE pd_areas ADD CONSTRAINT area_name_is_not_empty CHECK(char_length(area_name) > 0);
ALTER TABLE pd_locations ADD CONSTRAINT street_name_is_not_empty CHECK(char_length(street) > 0);

-- 10. Добавьте ограничения целостности, гарантирующие следующих исполнение условия: поля “острая” и “вегетарианская” 
-- могут принимать только значения 1 или 0; количество любого продукта в заказе не может быть отрицательным или превышать 100;
-- cрок, к которому надо доставить заказ, не может превышать дату и время заказа, заказ не может быть доставлен
-- до того как его сделали; цена товара не может быть отрицательной или нулевой.
-- поля hot и vegan у нас char, поэтому '1' or '0'
ALTER TABLE pd_products ADD CONSTRAINT vegan_bool CHECK (vegan = '0' OR vegan = '1');
ALTER TABLE pd_products ADD CONSTRAINT hot_bool CHECK (hot = '0' OR hot = '1');
ALTER TABLE pd_order_details ADD CONSTRAINT quantity_range CHECK (quantity BETWEEN 1 AND 100);
ALTER TABLE pd_products ADD CONSTRAINT price_range CHECK (price > 0);
ALTER TABLE pd_orders ADD CONSTRAINT exec_after_ordered CHECK (exec_date >= order_date);
-- не понял требование: "cрок, к которому надо доставить заказ, не может превышать дату и время заказа".
-- что такое дата и время заказа? 
-- Ниже моя интерпретация этого требования:
ALTER TABLE pd_orders ADD CONSTRAINT delivery_after_ordered CHECK (delivery_date >= order_date); 

-- Намеренно не объеденял разные ограничения на одной таблице в одно, чтобы в случае возникновения ошибок легче было распознавать из-за какого значения она вылетает
