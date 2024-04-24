/* 2a(i)
 * what is the most ordered item based on the number of times it appears in an order cart that checked out successfully? 
 * you are expected to return the product_id, and product_name and num_times_in_successful_orders where
*/

-- Create a common table expression (CTE) to filter add_to_cart events
with add_to_cart as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'add_to_cart'
),

-- Create a common table expression (CTE) to filter successful checkout events
-- With the assumption that successful checkout events have 'checkout' as the event_type and 'success' as the status.
successful_checkout as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'checkout' 
    and event_data ->> 'status' = 'success'
),

-- Create a common table expression (CTE) to filter remove_from_cart events
remove_from_cart as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'remove_from_cart'
),

-- Filter out items that were removed from the cart
active_cart_items as (
    select
        a.*
    from add_to_cart a
    left join remove_from_cart r
        on a.customer_id = r.customer_id and a.event_data ->> 'item_id' = r.event_data ->> 'item_id'
    where r.event_data ->> 'event_type' is null
 )
 
-- Most ordered item based on the number of times it appears in an order cart that checked out successfully
 select
 	p.id as "product_id", 
 	p.name as "product_name", 
 	count((a.event_data ->> 'item_id')::BIGINT) as "num_times_in_successful_orders"
from successful_checkout s
join active_cart_items a on s.customer_id = a.customer_id
join alt_school.products p on (a.event_data ->> 'item_id')::BIGINT = p.id
group by p.id, p.name
order by 3 desc
limit 1;


/* 2a(ii)
 * without considering currency, and without using the line_item table, 
 * find the top 5 spenders you are expected to return the customer_id, location, total_spend where
 */

-- Create a common table expression (CTE) to filter successful checkout events
-- With the assumption that successful checkout events have 'checkout' as the event_type and 'success' as the status.
with successful_checkout as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'checkout' 
    and event_data ->> 'status' = 'success'
),

-- Create a CTE to rank customers based on their total amount of money spent on orders
rank_spender as (
    select
        c.customer_id, 
        c."location",
        -- Calculate total spend for each customer
        sum(p.price * (e.event_data ->> 'item_id')::BIGINT) as "total_spend",
        -- Rank customers based on their total spend
        dense_rank() over(order by sum(p.price * (e.event_data ->> 'item_id')::BIGINT) desc) as "rank_spender"
    from 
        alt_school.customers c
    join 
        successful_checkout s on c.customer_id = s.customer_id
    join 
        alt_school.events e on s.customer_id = e.customer_id 
    join 
        alt_school.products p on (e.event_data ->> 'item_id')::BIGINT = p.id
    group by 1, 2
    order by 3 desc
)

-- Select top spender(s)
select 
    customer_id, 
    location, 
    total_spend
from 
    rank_spender r
where 
    r.rank_spender < 6; -- Filter for the top spender
    

/* 2b(i)
 * using the events table, 
 * Determine the most common location (country) where successful checkouts occurred. return location and checkout_count
*/

-- Create a common table expression (CTE) to filter successful checkout events
-- With the assumption that successful checkout events have 'checkout' as the event_type and 'success' as the status.
with successful_checkout as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'checkout' 
    and event_data ->> 'status' = 'success'
),

-- Rank locations based on the number of location (country) where successful checkouts occurred.
rank_checkout_count as (
    select
    	c.location, 
        count(s.customer_id) as "checkout_count",
        -- Rank locations based on their checkout count
        dense_rank() over(order by count(s.customer_id) desc) as "rank_checkout"
    from successful_checkout s
    join alt_school.customers c
        on s.customer_id = c.customer_id
    group by c.location
    order by 2 desc
)

-- Select the location with the highest rank checkout count
select 
    location, 
    checkout_count
from 
    rank_checkout_count r
where 
    r.rank_checkout = 1; -- Filter for the top rank checkout count
    

/* 2b(ii)
 * Using the events table, identify the customers who abandoned their carts
 * and count the number of events (excluding visits) that occurred before the abandonment.
 * Return the customer_id and num_events
 */

-- Create a common table expression (CTE) to filter add_to_cart events
with add_to_cart as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'add_to_cart'
),

-- Create a common table expression (CTE) to filter remove_from_cart events
remove_from_cart as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'remove_from_cart'
),

-- Filter out items that were removed from the cart
active_cart_items as (
    select
        a.*
    from add_to_cart a
    left join remove_from_cart r
        on a.customer_id = r.customer_id and a.event_data ->> 'item_id' = r.event_data ->> 'item_id'
    where r.event_data ->> 'event_type' is null
),

-- Create a common table expression (CTE) to filter checkout events
-- With the assumption that checkout events have 'checkout' as the event_type.
checkout as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'checkout'
),

-- Identify customers who abandoned their carts
-- With the assumption that customers can add items to their cart but leave without proceeding to checkout 
abandon as (
    select a.*
    from alt_school.events a
    left join checkout c
    on a.customer_id = c.customer_id
    where c.customer_id IS NULL
)

-- Count the number of events for each abandoned customer (excluding visits)
select 
    a.customer_id as "customer_id",
    count(a.event_data ->> 'event_type') as "num_events"
from abandon a
where a.event_data ->> 'event_type' != 'visit' --filter out events where event_type is visits
group by a.customer_id;


/* 2b(iii)
 * Find the average number of visits per customer,
 * considering only customers who completed a checkout! return average_visits to 2 decimal place
 */

-- Create a common table expression (CTE) to filter successful checkout events
-- With the assumption that successful checkout events have 'checkout' as the event_type and 'success' as the status.
with successful_checkout as (
    select *
    from alt_school.events e 
    where event_data ->> 'event_type' = 'checkout' 
    and event_data ->> 'status' = 'success'
),

-- Count the number of visit events for each customer who completed a checkout
sucessful_customer_visit as (
	select 
		e.customer_id,
		count(e.event_data ->> 'event_type') as "customer_visit_count"
	from alt_school.events e 
	join successful_checkout s
	on e.customer_id = s.customer_id
	where e.event_data ->> 'event_type' = 'visit'
	group by e.customer_id 
)

-- Calculate the average number of visits per customer who completed a checkout
select round(avg(customer_visit_count), 2) as "average_visits"
from sucessful_customer_visit;