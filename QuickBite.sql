create database quick;
use quick;

select *from customer;
select *from agent;
select *from orders;
select *from restaurant;

#Which cities recorded at least one order in 2022, and what were their total order counts and total revenue?

select c.city, count( o.orderid) as orders , round(sum(order_amount),2) as revenue from customer c
left join orders o
on  c.customerid = o.customerid
where year(order_date) = 2022
group by city
having count(orderid) >= 1
order by revenue desc;

#Which cuisine type generates the highest total revenue and order volume across the platform?

select cuisine_type , round(sum(order_amount),2) as revenue , count(distinct orderid) orders from orders o
left join restaurant r
on o.restaurantid = r.restaurantid
group by cuisine_type
order by revenue desc;

#What is each restaurant's total orders, total revenue, and average order value, ranked by total revenue?

select r.restaurant_name as restaurants , count(o.orderid) as orders , round(sum(o.order_amount),2) as revenue , round(avg(o.order_amount),2),
dense_rank() over(order by sum(o.order_amount) desc) as ranks from restaurant r
left join orders o
on r.restaurantid = o.restaurantid
group by restaurant_name 
order by revenue desc;

#What is the highest single order amount ever recorded per restaurant, along with the restaurant name and cuisine type?

select * from(
select o.orderid , r.restaurant_name , r.cuisine_type , sum(o.order_amount)  as rev,
dense_rank() over(partition by restaurant_name, cuisine_type order by sum(o.order_amount) desc) as ranks from orders o
inner join restaurant r
on o.restaurantid = r.restaurantid
group by orderid , restaurant_name , cuisine_type
order by rev desc
) as x
where ranks = 1;

#Who are the top 10 customers by lifetime spend, and what are their cities, total orders, and total amount spent?

select c.customerid , c.customer_name , c.city , count(o.orderid) as orders , round(sum(o.order_amount),2) as rev from customer c
inner join orders o
on c.customerid = o.customerid
group by c.customerid , c.customer_name , c.city
order by rev desc
limit 10;

#What is each delivery agent's total deliveries completed and average delivery time, ranked by total deliveries?

select agent_name , count(o.orderid) as orders , avg(delivery_minutes) as average , 
dense_rank() over(order by count(o.orderid) desc) as ranks from agent a
left join orders o
on a.agentid = o.agentid
group by agent_name;

#What is the average delivery time per city, ordered from fastest to slowest?

select c.city , round(avg(delivery_minutes),2) as average_time from customer c
left join orders o
on c.customerid = o.customerid
group by c.city
order by average_time;

#Which restaurants received orders in 2023 but had zero orders in 2022?

select r.restaurant_name, count(o.orderid) as orders_2023
from restaurant r
join orders o on r.restaurantid = o.restaurantid
where year(o.order_date) = 2023
and r.restaurantid not in (
    select restaurantid from orders where year(order_date) = 2022
)
group by r.restaurant_name;

#Which customers placed more than 5 orders and maintained an average order value above ₹600?

select distinct c.customerid , count(o.orderid) , round(avg(o.order_amount),2) from customer c
inner join orders o
on c.customerid = o.customerid
group by c.customerid
having count(o.orderid) > 5 and avg(o.order_amount) > 600;

#What are the total revenue, total orders, and average order value for each year from 2020 to 2023?

select *from(
select year(order_date) as year , round(sum(order_amount),2) as rev, count(orderid) as orders  , round(avg(order_amount),2) as avo from orders
group by year(order_date))
as x
where year in (2020,2021,2022,2023)
order by rev desc;

#For each cuisine type, which restaurant holds the highest average order rating, and what are its total orders?

select restaurant , cuisine_type , avg_rating , orders from(
select restaurant_name as restaurant ,cuisine_type , round(avg(o.rating),2) as avg_rating , count(o.orderid) as orders,
dense_rank() over(partition by cuisine_type order by round(avg(o.rating),2) desc) as ranks from restaurant r
left join orders o
on r.restaurantid = o.restaurantid
group by restaurant_name , cuisine_type
order by cuisine_type
) as x
where ranks = 1;

#What is the transaction count, total revenue, and percentage revenue share for each payment mode?

select modes , transactions , round(sum(rev)/(select sum(order_amount) from orders)*100,2) as per_rev from(
select payment_mode as modes , count(payment_mode) as transactions , round(sum(order_amount),2) as rev
from orders
group by payment_mode
)as x
group by modes;

#Which restaurant achieved the highest percentage revenue growth from 2022 to 2023?

select * from(
		select * , round((curr_rev-prev_rev)/prev_rev*100,2) as per_rev, dense_rank() over(order by round((curr_rev-prev_rev)/prev_rev*100,2) desc)  as ranks from(
						select restaurant_name as restaurant ,year(order_date) as years , round(sum(order_amount),2) as curr_rev,
						round(lag(sum(order_amount)) over(partition by restaurant_name order by year(order_date)),2) as prev_rev
						from restaurant r
						left join orders o
						on r.restaurantid = o.restaurantid
						where year(order_date) in (2022,2023)
						group by restaurant_name , year(order_date) 
		) as x
) as y
where ranks = 1;

#For the 5 most active customers by total orders, what are their orders and revenue broken down by year (2020–2023)?

select c.customerid, c.customer_name, year(o.order_date) as years,
       count(o.orderid) as orders, round(sum(o.order_amount),2) as revenue
from customer c
inner join orders o on c.customerid = o.customerid
where c.customerid in (
    select customerid from (
        select customerid, count(orderid) as total_orders
        from orders
        group by customerid
        order by total_orders desc
        limit 5
    ) top5
)
group by c.customerid, c.customer_name, year(o.order_date)
order by c.customerid, years;

#For each city, how many delivery agents are assigned, and what is the total orders delivered and average orders per agent?

select * , round(total_orders/total_agent,2) as Avg_order from(
select a.city , count(distinct a.agentid) as total_agent, count(o.orderid) as total_orders from agent a 
left join orders o
on a.agentid = o.agentid
group by city
)as x
order by city;

#Are there customers who share the same name and email address but have been assigned different CustomerIDs?

select distinct c1.customer_name , c1.email from customer c1
inner join customer c2
on c1.customer_name  = c2.customer_name and c1.email = c2.email
where c1.customerid <> c2.customerid;

#Did any delivery agent complete an unusually high number of orders (more than 50) on a single calendar day? Show the date and order count.

select agentid, order_date,count(orderid) from orders
group by agentid ,order_date
having count(orderid) >50;

#Which orders have an Order_Amount more than 3 times the platform-wide average order amount?

select orderid , round(sum(order_amount),2) as rev from orders
group by orderid
having sum(order_amount) > 3*(select avg(order_amount) from orders)
order by rev desc;

#Which orders had a Delivery_Minutes value exceeding 180 minutes? Include the restaurant name, agent name, city, and delivery time.

select o.orderid , r.restaurant_name , a.agent_name , r.city , avg(delivery_minutes) as minutes from restaurant r
join orders o
on r.restaurantid = o.restaurantid
join agent a
on o.agentid = a.agentid
group by orderid , restaurant_name, agent_name, r.city
having minutes > 180
order by minutes;

#Are there any orders in Fact_Orders where the Order_Date is earlier than the customer's Member_Since date?

select o.orderid, c.customerid , c.customer_name, o.order_date , c.member_since from orders o
left join customer c
on c.customerid = o.customerid
where o.order_date < c.member_since;

#List all orders placed by CustomerIDs identified as duplicates (same name and email as another customer), showing order details and both the original and duplicate CustomerIDs

select o.orderid, c2.customerid as original_customerid, c1.customerid as duplicate_customerid,
       o.order_date, o.order_amount
from customer c1
join orders o on c1.customerid = o.customerid
join customer c2 on c1.customer_name = c2.customer_name
                 and c1.email = c2.email
                 and c1.customerid <> c2.customerid
where c1.customerid > c2.customerid
order by o.orderid;