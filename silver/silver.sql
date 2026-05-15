-- Création du schéma Silver
CREATE SCHEMA IF NOT EXISTS LINKEDIN.SILVER;

-- Table job_postings nettoyée et typée
CREATE OR REPLACE TABLE LINKEDIN.SILVER.JOB_POSTINGS AS
SELECT
    CAST(job_id AS NUMBER) AS job_id,
    company_name,
    title,
    description,
    CAST(max_salary AS FLOAT) AS max_salary,
    CAST(med_salary AS FLOAT) AS med_salary,
    CAST(min_salary AS FLOAT) AS min_salary,
    pay_period,
    formatted_work_type,
    location,
    CAST(applies AS NUMBER) AS applies,
    TO_TIMESTAMP(CAST(original_listed_time AS NUMBER) / 1000) AS original_listed_time,
    CASE WHEN remote_allowed = '1.0' THEN TRUE WHEN remote_allowed = '0.0' THEN FALSE ELSE NULL END AS remote_allowed,
    CAST(views AS NUMBER) AS views,
    job_posting_url,
    application_url,
    application_type,
    TO_TIMESTAMP(CAST(expiry AS NUMBER) / 1000) AS expiry,
    TO_TIMESTAMP(CAST(closed_time AS NUMBER) / 1000) AS closed_time,
    formatted_experience_level,
    skills_desc,
    TO_TIMESTAMP(CAST(listed_time AS NUMBER) / 1000) AS listed_time,
    posting_domain,
    CASE WHEN sponsored = '1.0' THEN TRUE WHEN sponsored = '0.0' THEN FALSE ELSE NULL END AS sponsored,
    work_type,
    currency,
    compensation_type
FROM LINKEDIN.BRONZE.JOB_POSTINGS
WHERE job_id IS NOT NULL;

-- Table benefits nettoyée
CREATE OR REPLACE TABLE LINKEDIN.SILVER.BENEFITS AS
SELECT
    CAST(job_id AS NUMBER) AS job_id,
    CAST(inferred AS BOOLEAN) AS inferred,
    type
FROM LINKEDIN.BRONZE.BENEFITS
WHERE job_id IS NOT NULL;

-- Table employee_counts nettoyée
CREATE OR REPLACE TABLE LINKEDIN.SILVER.EMPLOYEE_COUNTS AS
SELECT
    CAST(company_id AS NUMBER) AS company_id,
    CAST(employee_count AS NUMBER) AS employee_count,
    CAST(follower_count AS NUMBER) AS follower_count,
    TO_TIMESTAMP(CAST(time_recorded AS NUMBER) / 1000) AS time_recorded
FROM LINKEDIN.BRONZE.EMPLOYEE_COUNTS
WHERE company_id IS NOT NULL;

-- Table job_skills nettoyée
CREATE OR REPLACE TABLE LINKEDIN.SILVER.JOB_SKILLS AS
SELECT
    CAST(job_id AS NUMBER) AS job_id,
    skill_abr
FROM LINKEDIN.BRONZE.JOB_SKILLS
WHERE job_id IS NOT NULL;

-- Table companies extraite du JSON
CREATE OR REPLACE TABLE LINKEDIN.SILVER.COMPANIES AS
SELECT
    CAST(raw_data:company_id::STRING AS NUMBER) AS company_id,
    raw_data:name::STRING AS name,
    raw_data:description::STRING AS description,
    CAST(raw_data:company_size::STRING AS NUMBER) AS company_size,
    raw_data:state::STRING AS state,
    raw_data:country::STRING AS country,
    raw_data:city::STRING AS city,
    raw_data:zip_code::STRING AS zip_code,
    raw_data:address::STRING AS address,
    raw_data:url::STRING AS url
FROM LINKEDIN.BRONZE.COMPANIES_RAW
WHERE raw_data:company_id IS NOT NULL;

-- Table company_industries extraite du JSON
CREATE OR REPLACE TABLE LINKEDIN.SILVER.COMPANY_INDUSTRIES AS
SELECT
    CAST(raw_data:company_id::STRING AS NUMBER) AS company_id,
    raw_data:industry::STRING AS industry
FROM LINKEDIN.BRONZE.COMPANY_INDUSTRIES_RAW
WHERE raw_data:company_id IS NOT NULL;

-- Table company_specialities extraite du JSON
CREATE OR REPLACE TABLE LINKEDIN.SILVER.COMPANY_SPECIALITIES AS
SELECT
    CAST(raw_data:company_id::STRING AS NUMBER) AS company_id,
    raw_data:speciality::STRING AS speciality
FROM LINKEDIN.BRONZE.COMPANY_SPECIALITIES_RAW
WHERE raw_data:company_id IS NOT NULL;

-- Table job_industries extraite du JSON
CREATE OR REPLACE TABLE LINKEDIN.SILVER.JOB_INDUSTRIES AS
SELECT
    CAST(raw_data:job_id::STRING AS NUMBER) AS job_id,
    raw_data:industry_id::STRING AS industry_id
FROM LINKEDIN.BRONZE.JOB_INDUSTRIES_RAW
WHERE raw_data:job_id IS NOT NULL;
