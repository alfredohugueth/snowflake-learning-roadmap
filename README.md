# Snowflake Learning Roadmap

This repository documents my progress studying Snowflake as a Data Engineer in 2026.  
Each day I record what I practice, what I learn, and the concepts I master.

---

## 📅 Day 1 — Environment Setup and First Steps

### ✔ Initial Setup
- Warehouse creation
- Database creation
- Schema creation

### ✔ Staging and Data Loading
- Stage creation
- CSV file upload
- Table creation
- COPY INTO to load the data
- Data validation

### ✔ Concepts Learned
- Warehouse Cache
- Result Cache

---

## Next Steps
- Create dimensional models
- Create fact models
- Practice time-travel and fail-safe

## 📅 Day 2 - Medallion architecture implementation

### ✔ Dimensional Modeling
- Creation of DIM_CUSTOMERS
- Renaming surrogate key to customer_key
- ensuring clean, consistent attributes

### ✔ Fact Modeling
- Creation of FACT_SUBSCRIPTION
- Validating referential integrity
- Checking for duplicates


### ✔ Time Travel & Fail-Safe Practice
- Executed a DELETE to simulate data loss
- Queried historical version using Time Travel
- Restored the table to its previous state
- Confirmed Snowflake's historical retention behaviour

### ✔ Concepts Learned
- Time Travel
- Fail-Safe
- Surrogate keys in dimensional modeling
- integrity Validations (Anti-joins)

## Next Steps
- Create analytical views
- Begin dbt modeling
- Add tests

