-- Création de la base de données et des schémas
CREATE DATABASE IF NOT EXISTS LINKEDIN;
CREATE SCHEMA IF NOT EXISTS LINKEDIN.BRONZE;

-- Stage externe pointant vers le bucket S3
CREATE OR REPLACE STAGE LINKEDIN.BRONZE.linkedin_stage
    URL = 's3://snowflake-lab-bucket/';

-- Format de fichier pour les CSV
CREATE OR REPLACE FILE FORMAT LINKEDIN.BRONZE.csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '');

-- Format de fichier pour les JSON
CREATE OR REPLACE FILE FORMAT LINKEDIN.BRONZE.json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE;

-- Table job_postings : toutes les offres d'emploi
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.JOB_POSTINGS (
    job_id STRING, company_name STRING, title STRING,
    description STRING, max_salary STRING, med_salary STRING,
    min_salary STRING, pay_period STRING, formatted_work_type STRING,
    location STRING, applies STRING, original_listed_time STRING,
    remote_allowed STRING, views STRING, job_posting_url STRING,
    application_url STRING, application_type STRING, expiry STRING,
    closed_time STRING, formatted_experience_level STRING,
    skills_desc STRING, listed_time STRING, posting_domain STRING,
    sponsored STRING, work_type STRING, currency STRING,
    compensation_type STRING
);

COPY INTO LINKEDIN.BRONZE.JOB_POSTINGS
    FROM @LINKEDIN.BRONZE.linkedin_stage/job_postings.csv
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.csv_format')
    ON_ERROR = 'CONTINUE';

-- Table benefits : avantages associés aux offres
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.BENEFITS (
    job_id STRING, inferred STRING, type STRING
);

COPY INTO LINKEDIN.BRONZE.BENEFITS
    FROM @LINKEDIN.BRONZE.linkedin_stage/benefits.csv
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.csv_format')
    ON_ERROR = 'CONTINUE';

-- Table employee_counts : nombre d'employés par entreprise
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.EMPLOYEE_COUNTS (
    company_id STRING, employee_count STRING,
    follower_count STRING, time_recorded STRING
);

COPY INTO LINKEDIN.BRONZE.EMPLOYEE_COUNTS
    FROM @LINKEDIN.BRONZE.linkedin_stage/employee_counts.csv
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.csv_format')
    ON_ERROR = 'CONTINUE';

-- Table job_skills : compétences par offre
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.JOB_SKILLS (
    job_id STRING, skill_abr STRING
);

COPY INTO LINKEDIN.BRONZE.JOB_SKILLS
    FROM @LINKEDIN.BRONZE.linkedin_stage/job_skills.csv
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.csv_format')
    ON_ERROR = 'CONTINUE';

-- Table companies : données brutes JSON
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.COMPANIES_RAW (
    raw_data VARIANT
);

COPY INTO LINKEDIN.BRONZE.COMPANIES_RAW
    FROM @LINKEDIN.BRONZE.linkedin_stage/companies.json
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.json_format')
    ON_ERROR = 'CONTINUE';

-- Table company_industries : secteurs par entreprise
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.COMPANY_INDUSTRIES_RAW (
    raw_data VARIANT
);

COPY INTO LINKEDIN.BRONZE.COMPANY_INDUSTRIES_RAW
    FROM @LINKEDIN.BRONZE.linkedin_stage/company_industries.json
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.json_format')
    ON_ERROR = 'CONTINUE';

-- Table company_specialities : spécialités par entreprise
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.COMPANY_SPECIALITIES_RAW (
    raw_data VARIANT
);

COPY INTO LINKEDIN.BRONZE.COMPANY_SPECIALITIES_RAW
    FROM @LINKEDIN.BRONZE.linkedin_stage/company_specialities.json
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.json_format')
    ON_ERROR = 'CONTINUE';

-- Table job_industries : secteurs par offre d'emploi
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.JOB_INDUSTRIES_RAW (
    raw_data VARIANT
);

COPY INTO LINKEDIN.BRONZE.JOB_INDUSTRIES_RAW
    FROM @LINKEDIN.BRONZE.linkedin_stage/job_industries.json
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.json_format')
    ON_ERROR = 'CONTINUE';
