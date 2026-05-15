-- Création du schéma Gold
CREATE SCHEMA IF NOT EXISTS LINKEDIN.GOLD;

-- Top 10 des titres de postes les plus publiés par industrie
CREATE OR REPLACE VIEW LINKEDIN.GOLD.TOP10_TITRES_PAR_INDUSTRIE AS
WITH ranked AS (
    SELECT
        ci.industry,
        jp.title,
        COUNT(*) AS nb_offres,
        ROW_NUMBER() OVER (PARTITION BY ci.industry ORDER BY COUNT(*) DESC) AS rang
    FROM LINKEDIN.SILVER.JOB_POSTINGS jp
    JOIN LINKEDIN.SILVER.COMPANY_INDUSTRIES ci
        ON CAST(jp.company_name AS NUMBER) = ci.company_id
    GROUP BY ci.industry, jp.title
)
SELECT industry, title, nb_offres, rang
FROM ranked
WHERE rang <= 10;

-- Top 10 des postes les mieux rémunérés par industrie
CREATE OR REPLACE VIEW LINKEDIN.GOLD.TOP10_SALAIRES_PAR_INDUSTRIE AS
WITH ranked AS (
    SELECT
        ci.industry,
        jp.title,
        ROUND(AVG(jp.med_salary), 2) AS salaire_moyen,
        ROW_NUMBER() OVER (PARTITION BY ci.industry ORDER BY AVG(jp.med_salary) DESC) AS rang
    FROM LINKEDIN.SILVER.JOB_POSTINGS jp
    JOIN LINKEDIN.SILVER.COMPANY_INDUSTRIES ci
        ON CAST(jp.company_name AS NUMBER) = ci.company_id
    WHERE jp.med_salary IS NOT NULL
    GROUP BY ci.industry, jp.title
)
SELECT industry, title, salaire_moyen, rang
FROM ranked
WHERE rang <= 10;

-- Répartition des offres par taille d'entreprise
CREATE OR REPLACE VIEW LINKEDIN.GOLD.REPARTITION_TAILLE_ENTREPRISE AS
SELECT
    c.company_size,
    COUNT(jp.job_id) AS nb_offres
FROM LINKEDIN.SILVER.JOB_POSTINGS jp
JOIN LINKEDIN.SILVER.COMPANIES c
    ON CAST(jp.company_name AS NUMBER) = c.company_id
GROUP BY c.company_size
ORDER BY c.company_size;

-- Répartition des offres par secteur d'activité
CREATE OR REPLACE VIEW LINKEDIN.GOLD.REPARTITION_SECTEUR AS
SELECT
    ci.industry,
    COUNT(jp.job_id) AS nb_offres
FROM LINKEDIN.SILVER.JOB_POSTINGS jp
JOIN LINKEDIN.SILVER.COMPANY_INDUSTRIES ci
    ON CAST(jp.company_name AS NUMBER) = ci.company_id
GROUP BY ci.industry
ORDER BY nb_offres DESC;

-- Répartition des offres par type d'emploi
CREATE OR REPLACE VIEW LINKEDIN.GOLD.REPARTITION_TYPE_EMPLOI AS
SELECT
    formatted_work_type,
    COUNT(job_id) AS nb_offres
FROM LINKEDIN.SILVER.JOB_POSTINGS
WHERE formatted_work_type IS NOT NULL
GROUP BY formatted_work_type
ORDER BY nb_offres DESC;
