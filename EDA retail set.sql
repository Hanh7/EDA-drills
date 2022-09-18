use retail;
--data profiling: khao sat du lieu

select table_name, column_name, data_type,
character_maximum_length, is_nullable 
from information_schema.columns 
where table_name = 'customers_5';

--2. Quan sát table: customers_5
select top 10 * from customers_5;

--3. Bảng có bao nhiêu dòng?
select count (*) from customers_5;

--4. Data value có fit với business meaning
select top 10 * from products;
select distinct size from products;

select distinct year(order_date) from orders_2;
select top 10 * from orders_2;
select top 10 * from sales;

--EDA dữ liệu: business hypothesis

--demographic: age
select top 10 * from customers_5;

select max(age), min(age) from customers_5;
--câu hỏi: chia nhóm khách hàng như thế (20-80) => phân cụm theo độ tuổi
--phân loại khách hàng theo độ tuổi, đối với những khách hàng có đặt order
common table expression 
with ten_cte as (_)
select .... from ten_cte;

with customer_age as
(select customer_id,
case when age >=20 and age <= 23 then 'student'
    when age >= 24 and age <= 35 then 'young professional'
    when age >= 36 and age <= 49 then 'middle age'
    when age >= 50 and age <= 65 then 'pre-retiree'
    when age > 65 then 'retiree' end as age_bin
from customers_5)
select age_bin, count (customer_id) slkh
from customer_age
where customer_id in (select distinct customer_id from orders_2)--subquery with IN, returns multi-value
group by age_bin;

--demographic: location
--xem xét phân bổ active user tại các vùng kinh tế

select state, count (customer_id) slkh
from customers_5 
where customer_id in (select distinct customer_id from orders_2)
group by state;

--demographic: gender
select gender, count (customer_id) slkh
from customers_5 
where customer_id in (select distinct customer_id from orders_2)
group by gender;

--tao mot bang dem demographic trong tableau --công cụ BI
select a.customer_id, b.age, b.gender, b.state 
from 
    (select distinct customer_id 
    from orders_2) a--là một bảng fact 
left join 
    (select customer_id, age, gender, state 
    from customers_5) b 
on a.customer_id = b.customer_id;


--shopping habits
--tao bang co customer_id, total_price, order_date
--de tinh toan RFM
select max(order_date), min(order_date) from orders_2;

with rfm_prepare as
    (select b.customer_id, 
    a.order_id, 
    b.order_date, 
    b.delivery_date, 
    a.total_price 
    from 
        (select order_id, total_price
        from sales) a 
    left join 
        (select order_id, customer_id, order_date, delivery_date 
        from orders_2) b 
    on a.order_id = b.order_id) 
, rfm_calculation as
    (select customer_id, 
    datediff(day, max(order_date), '2021-12-31') recency, 
    count (day(order_date)) frequency, 
    sum(total_price) monetary
    from rfm_prepare
    group by customer_id)
select * from rfm_calculation;

--champion products (top products)
select top 10 * from sales;

select top 10 a.product_id, product_name, description, sales_, value_ 
from 
    (select product_id, count (sales_id) sales_, sum(total_price) value_
    from sales
    group by product_id) a 
left join 
    (select product_id, product_name, description
    from products) b 
on a.product_id = b.product_id
order by sales_ desc;
