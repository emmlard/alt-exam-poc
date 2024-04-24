-- Create schema
CREATE SCHEMA IF NOT EXISTS ALT_SCHOOL;


-- create and populate products tables
create table if not exists ALT_SCHOOL.PRODUCTS
(
    id  bigint primary key,
    name varchar not null,
    price numeric(10, 2) not null
);

COPY ALT_SCHOOL.PRODUCTS (id, name, price)
FROM '/data/products.csv' DELIMITER ',' CSV HEADER;


-- create and populate orders tables
create table if not exists ALT_SCHOOL.ORDERS
(
    order_id uuid not null primary key,
    customer_id uuid not null,
    status varchar not null,
    checked_out_at timestamp not null
);

COPY ALT_SCHOOL.ORDERS (order_id, customer_id, status, checked_out_at)
FROM '/data/orders.csv' DELIMITER ',' CSV HEADER;


-- create and populate line_items tables
create table if not exists ALT_SCHOOL.LINE_ITEMS
(
    line_item_id bigint primary key,
    order_id uuid not null,
    item_id bigint not null,
    quantity bigint not null
);

COPY ALT_SCHOOL.LINE_ITEMS (line_item_id, order_id, item_id, quantity)
FROM '/data/line_items.csv' DELIMITER ',' CSV HEADER;


-- create and populate events tables
create table if not exists ALT_SCHOOL.EVENTS
(
    event_id bigint primary key,
    customer_id uuid not null,
    event_data jsonb not null,
    event_timestamp timestamp not null
);

COPY ALT_SCHOOL.EVENTS (event_id,customer_id,event_data,event_timestamp)
FROM '/data/events.csv' DELIMITER ',' CSV HEADER;


-- create and populate customers tables
create table if not exists ALT_SCHOOL.CUSTOMERS
(
    customer_id uuid primary key,
    device_id uuid,
    location varchar,
    currency varchar
);

COPY ALT_SCHOOL.CUSTOMERS (customer_id,device_id,location,currency)
FROM '/data/customers.csv' DELIMITER ',' CSV HEADER;