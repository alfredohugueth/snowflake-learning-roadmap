-------- Lesson 2
--- CREATE SILVER LAYER AND CREATE TABLE CUSTOMERS AS IT WILL BE CONSUMED.
CREATE SCHEMA DB_DEV.INTERMEDIATE;

CREATE TABLE IF NOT EXISTS DB_DEV.INTERMEDIATE.CUSTOMERS AS
WITH CLEANED AS (
SELECT
    index AS row_id,
    customer_id,
    INITCAP(first_name) as first_name,
    INITCAP(last_name) as last_name,
    INITCAP(company) as company,
    INITCAP(city) as city,
    UPPER(country) as country,
    REGEXP_REPLACE(phone_1, '[^0-9]', '') as primary_phone_not_cleaned,
    REGEXP_REPLACE(phone_2, '[^0-9]', '') as secondary_phone_not_cleaned,
    LOWER(email) as email,
    TRY_TO_DATE(subscription_date, 'YYYY-MM-DD') as subscription_dt,
    LOWER(website) as website
FROM DB_DEV.RAW.CUSTOMERS
WHERE
    customer_id IS NOT NULL
    AND customer_id <> ''
    AND TRY_TO_DATE(subscription_date, 'YYYY-MM-DD') IS NOT NULL
    AND email like '%@%'
)
SELECT
    row_id,
    customer_id,
    first_name,
    last_name,
    company,
    city,
    country,
    email,
    subscription_dt,
    website,
    CASE 
        WHEN LENGTH(primary_phone_not_cleaned) < 10 THEN 'INVALID'
        ELSE
            /* country code = todo antes de los últimos 10 dígitos */
            '+' ||
            SUBSTR(primary_phone_not_cleaned, 1,              LENGTH(primary_phone_not_cleaned) - 10) ||
            '(' ||
            SUBSTR(primary_phone_not_cleaned, LENGTH(primary_phone_not_cleaned) - 9, 3) ||
            ')' ||
            SUBSTR(primary_phone_not_cleaned, LENGTH(primary_phone_not_cleaned) - 6, 7)
    END AS primary_phone,
    CASE 
        WHEN LENGTH(secondary_phone_not_cleaned) < 10 THEN 'INVALID'
        ELSE
            /* country code = todo antes de los últimos 10 dígitos */
            '+' ||
            SUBSTR(secondary_phone_not_cleaned, 1,              LENGTH(secondary_phone_not_cleaned) - 10) ||
            '(' ||
            SUBSTR(secondary_phone_not_cleaned, LENGTH(secondary_phone_not_cleaned) - 9, 3) ||
            ')' ||
            SUBSTR(secondary_phone_not_cleaned, LENGTH(secondary_phone_not_cleaned) - 6, 7)
    END AS secondary_phone
FROM cleaned;



SELECT DISTINCT PRIMARY_PHONE FROM DB_DEV.INTERMEDIATE.CUSTOMERS;



------ create the CLEARER
CREATE SCHEMA IF NOT EXISTS DB_DEV.CLEAN;
CREATE TABLE IF NOT EXISTS DB_DEV.CLEAN.CUSTOMERS AS 
SELECT 
    row_id,
    customer_id,
    first_name,
    last_name,
    company,
    city,
    country,
    email,
    subscription_dt,
    website,
    primary_phone,
    secondary_phone,
FROM DB_DEV.INTERMEDIATE.CUSTOMERS
WHERE
    primary_phone <> 'INVALID'
    AND secondary_phone <> 'INVALID';



SELECT *
FROM DB_DEV.CLEAN.CUSTOMERS
WHERE primary_phone = 'INVALID'
   OR secondary_phone = 'INVALID';

SELECT *
FROM DB_DEV.CLEAN.CUSTOMERS
WHERE LENGTH(primary_phone) < 5
   OR LENGTH(secondary_phone) < 5;

SELECT *
FROM DB_DEV.CLEAN.CUSTOMERS
WHERE country IS NULL
   OR country = '';

------- CRATE THE STAGING LAYER
CREATE SCHEMA IF NOT EXISTS DB_DEV.STAGING;

CREATE OR REPLACE VIEW DB_DEV.STAGING.STG_CUSTOMERS AS
SELECT
    ROW_ID AS row_id,
    TRIM(CUSTOMER_ID) AS customer_id,
    TRIM(FIRST_NAME) AS first_name,
    TRIM(LAST_NAME) AS last_name,
    TRIM(COMPANY) AS company,
    TRIM(CITY) AS city,
    UPPER(TRIM(COUNTRY)) AS country,
    LOWER(TRIM(EMAIL)) AS email,
    SUBSCRIPTION_DT AS subscription_date,
    TRIM(WEBSITE) AS website,
    TRIM(PRIMARY_PHONE) AS primary_phone,
    TRIM(SECONDARY_PHONE) AS secondary_phone
FROM DB_DEV.CLEAN.CUSTOMERS;



-------- Create Dimensions
CREATE SCHEMA DB_DEV.GOLD;
CREATE OR REPLACE TABLE DB_DEV.GOLD.DIM_CUSTOMERS (
    customer_key NUMBER(38,0) PRIMARY KEY,
    customer_id VARCHAR(100), -- NATURAL KEY
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100),
    email VARCHAR(100),
    website VARCHAR(100),
    primary_phone VARCHAR(100),
    secondary_phone VARCHAR(100) 
)
AS
SELECT
    row_id as customer_key,
    customer_id,
    first_name,
    last_name,
    company,
    city,
    country,
    email,
    website,
    primary_phone,
    secondary_phone
FROM DB_DEV.STAGING.STG_CUSTOMERS;

--- create fact table
CREATE TABLE IF NOT EXISTS DB_DEV.GOLD.FACT_SUBSCRIPTIONS (
    subscription_sk NUMBER(38,0) IDENTITY(1,1) PRIMARY KEY, 
    customer_key NUMBER(38,0),         
    subscription_date DATE
);

INSERT INTO DB_DEV.GOLD.FACT_SUBSCRIPTIONS (customer_key, subscription_date)
SELECT
    row_id AS customer_key,
    subscription_date
FROM DB_DEV.STAGING.STG_CUSTOMERS;


select * from DB_DEV.GOLD.FACT_SUBSCRIPTIONS;



------ DATA VALIDATIONS
SELECT fs.customer_key
from DB_DEV.GOLD.FACT_SUBSCRIPTIONS fs
LEFT JOIN DB_DEV.GOLD.DIM_CUSTOMERS dc
    ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;

SELECT customer_key, COUNT(*) AS total
FROM DB_DEV.GOLD.FACT_SUBSCRIPTIONS
GROUP BY customer_key
HAVING COUNT(*) > 1;
