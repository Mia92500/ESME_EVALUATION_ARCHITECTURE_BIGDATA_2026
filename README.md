# Projet : Analyse des Offres d'Emploi LinkedIn avec Snowflake

**Groupe :** Mia Teixeira, Moé Al-Asbahi  
**École :** ESME  
**Année :** 2026

---

## Objectif

Pour ce projet, on a utilisé un dataset LinkedIn contenant des milliers d'offres d'emploi. L'idée c'était de charger ces données dans Snowflake, les nettoyer, puis créer des visualisations avec Streamlit pour analyser le marché de l'emploi.

---

## Architecture Medallion

On a organisé les données en 3 couches :

- **Bronze** : on charge les fichiers tels quels depuis S3, sans rien toucher
- **Silver** : on nettoie et on type les données correctement
- **Gold** : on crée des vues agrégées prêtes pour les graphiques

---

## Notebooks Snowflake

- [Bronze](https://app.snowflake.com/apqavtf/yhb73244/#/workspaces/ws/USER%24/PUBLIC/DEFAULT%24/TPLinkesdin_Bronze.sql)
- [Silver](https://app.snowflake.com/apqavtf/yhb73244/#/workspaces/ws/USER%24/PUBLIC/DEFAULT%24/TPLinkesdin_Silver.sql)
- [Gold](https://app.snowflake.com/apqavtf/yhb73244/#/workspaces/ws/USER%24/PUBLIC/DEFAULT%24/TPLinkesdin_Gold.sql)
- [Dashboard Streamlit](https://app.snowflake.com/apqavtf/yhb73244/#/streamlit-apps/LINKEDIN.GOLD.FUYQWH3JATGNGSM2)

---

## Jeu de Données

Les fichiers sont disponibles dans le bucket S3 : `s3://snowflake-lab-bucket/`

| Fichier | Description |
|---|---|
| job_postings.csv | Offres d'emploi |
| benefits.csv | Avantages associés aux offres |
| companies.json | Informations sur les entreprises |
| company_industries.json | Secteurs par entreprise |
| company_specialities.json | Spécialités par entreprise |
| employee_counts.csv | Nombre d'employés par entreprise |
| job_industries.json | Secteurs par offre |
| job_skills.csv | Compétences par offre |

---

## Phase 1 : Couche Bronze

La couche Bronze c'est la zone d'atterrissage des données. On charge tout depuis S3 sans rien modifier pour garder une source de vérité.

### 1. Configuration de l'environnement & Stage

On commence par créer la base de données et un stage externe qui pointe vers le bucket S3 :

```sql
-- Création de la base de données et du schéma Bronze
CREATE DATABASE IF NOT EXISTS LINKEDIN;
CREATE SCHEMA IF NOT EXISTS LINKEDIN.BRONZE;

-- Stage externe pointant vers le bucket S3
CREATE OR REPLACE STAGE LINKEDIN.BRONZE.linkedin_stage
    URL = 's3://snowflake-lab-bucket/';

-- Format pour les fichiers CSV
CREATE OR REPLACE FILE FORMAT LINKEDIN.BRONZE.csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '');

-- Format pour les fichiers JSON
CREATE OR REPLACE FILE FORMAT LINKEDIN.BRONZE.json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE;
```

### 2. Chargement des fichiers CSV

Pour les CSV, on met toutes les colonnes en STRING. Comme ça si une valeur de date ou de nombre est mal formatée, Snowflake ne rejette pas la ligne.

```sql
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
```

On fait pareil pour benefits, employee_counts et job_skills.

### 3. Chargement des fichiers JSON

Pour les JSON, on utilise le type VARIANT qui permet de stocker du JSON brut :

```sql
CREATE OR REPLACE TABLE LINKEDIN.BRONZE.COMPANIES_RAW (
    raw_data VARIANT
);

COPY INTO LINKEDIN.BRONZE.COMPANIES_RAW
    FROM @LINKEDIN.BRONZE.linkedin_stage/companies.json
    FILE_FORMAT = (FORMAT_NAME = 'LINKEDIN.BRONZE.json_format')
    ON_ERROR = 'CONTINUE';
```

**Résultat :** 21 993 offres d'emploi chargées avec 0 erreur.

---

## Phase 2 : Couche Silver

Maintenant on nettoie et on type correctement toutes les données.

### 1. Typage des colonnes

On convertit chaque colonne dans son bon type. Les timestamps sont en Unix donc on divise par 1000 pour les convertir :

```sql
CREATE OR REPLACE TABLE LINKEDIN.SILVER.JOB_POSTINGS AS
SELECT
    CAST(job_id AS NUMBER) AS job_id,
    company_name,
    title,
    CAST(max_salary AS FLOAT) AS max_salary,
    CAST(med_salary AS FLOAT) AS med_salary,
    CAST(min_salary AS FLOAT) AS min_salary,
    TO_TIMESTAMP(CAST(original_listed_time AS NUMBER) / 1000) AS original_listed_time,
    TO_TIMESTAMP(CAST(listed_time AS NUMBER) / 1000) AS listed_time,
    formatted_work_type,
    location,
    formatted_experience_level
FROM LINKEDIN.BRONZE.JOB_POSTINGS
WHERE job_id IS NOT NULL;
```

### 2. Problème avec les booléens

Les colonnes `remote_allowed` et `sponsored` contenaient `1.0` et `0.0` au lieu de `true`/`false`. Snowflake ne les reconnaissait pas comme booléens donc on a utilisé un CASE WHEN :

```sql
CASE WHEN remote_allowed = '1.0' THEN TRUE 
     WHEN remote_allowed = '0.0' THEN FALSE 
     ELSE NULL END AS remote_allowed,
```

### 3. Extraction des JSON

Pour les tables JSON, on extrait chaque champ avec la syntaxe Snowflake :

```sql
CREATE OR REPLACE TABLE LINKEDIN.SILVER.COMPANIES AS
SELECT
    CAST(raw_data:company_id::STRING AS NUMBER) AS company_id,
    raw_data:name::STRING AS name,
    CAST(raw_data:company_size::STRING AS NUMBER) AS company_size,
    raw_data:country::STRING AS country,
    raw_data:city::STRING AS city
FROM LINKEDIN.BRONZE.COMPANIES_RAW
WHERE raw_data:company_id IS NOT NULL;
```

---

## Phase 3 : Couche Gold

On crée 5 vues agrégées pour les analyses. On utilise des ROW_NUMBER() pour récupérer les top 10 par industrie.

### Problème de jointure

En voulant joindre les offres avec les entreprises, on a réalisé que `company_name` dans job_postings contenait des IDs numériques et non des noms. On a donc joint sur `company_id` :

```sql
JOIN LINKEDIN.SILVER.COMPANY_INDUSTRIES ci
    ON CAST(jp.company_name AS NUMBER) = ci.company_id
```

### Les 5 vues Gold

```sql
-- Top 10 titres par industrie
CREATE OR REPLACE VIEW LINKEDIN.GOLD.TOP10_TITRES_PAR_INDUSTRIE AS
WITH ranked AS (
    SELECT ci.industry, jp.title, COUNT(*) AS nb_offres,
        ROW_NUMBER() OVER (PARTITION BY ci.industry ORDER BY COUNT(*) DESC) AS rang
    FROM LINKEDIN.SILVER.JOB_POSTINGS jp
    JOIN LINKEDIN.SILVER.COMPANY_INDUSTRIES ci
        ON CAST(jp.company_name AS NUMBER) = ci.company_id
    GROUP BY ci.industry, jp.title
)
SELECT industry, title, nb_offres FROM ranked WHERE rang <= 10;

-- Répartition par type d'emploi
CREATE OR REPLACE VIEW LINKEDIN.GOLD.REPARTITION_TYPE_EMPLOI AS
SELECT formatted_work_type, COUNT(job_id) AS nb_offres
FROM LINKEDIN.SILVER.JOB_POSTINGS
WHERE formatted_work_type IS NOT NULL
GROUP BY formatted_work_type
ORDER BY nb_offres DESC;
```

---

## Analyses et Résultats

### 1. Top 10 des titres de postes les plus publiés par industrie
![top10_titres](screenshots/top10_titres.png)

Les postes les plus publiés varient beaucoup selon l'industrie. Dans l'IT ce sont surtout des postes techniques, dans d'autres secteurs plutôt des postes commerciaux.

### 2. Top 10 des postes les mieux rémunérés par industrie
![top10_salaires](screenshots/top10_salaires.png)

Les salaires les plus élevés sont dans les secteurs technologiques et financiers.

### 3. Répartition des offres par taille d'entreprise
![taille_entreprise](screenshots/taille_entreprise.png)

Les grandes entreprises (taille 7) publient beaucoup plus d'offres. La taille va de 1 (petite) à 7 (grande).

### 4. Répartition des offres par secteur d'activité
![secteur](screenshots/secteur_activite.png)

Les secteurs les plus actifs sont les RH, les textiles et la technologie grand public.

### 5. Répartition des offres par type d'emploi
![type_emploi](screenshots/type_emploi.png)

Le temps plein domine largement avec plus de 12 000 offres. Les stages et le bénévolat sont très peu représentés.

---

## Technologies Utilisées

- Snowflake (SQL, Snowpark)
- Streamlit
- AWS S3 (bucket fourni, accès via Snowflake Stage)
