# Projet : Analyse des Offres d'Emploi LinkedIn avec Snowflake

**Groupe :** Mia Teixeira, Moé Al-Asbahi  
**École :** ESME  
**Année :** 2026

---

## Objectif

Ce projet analyse des milliers d'offres d'emploi LinkedIn en utilisant Snowflake pour le stockage et le traitement des données, et Streamlit pour les visualisations interactives.

---

## Architecture Medallion

Les données sont organisées en 3 couches :

- **Bronze** : ingestion des données brutes depuis le bucket S3, sans transformation
- **Silver** : nettoyage, typage des colonnes et extraction des données JSON
- **Gold** : vues agrégées prêtes pour l'analyse

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

## Structure du Projet
---

## Phase 1 : Couche Bronze

Ingestion des données brutes depuis le bucket S3 sans transformation. Toutes les colonnes sont chargées en STRING pour éviter les erreurs de format.

**Résultat :** 21 993 offres d'emploi chargées avec 0 erreur.

---

## Phase 2 : Couche Silver

Nettoyage et typage des données :
- Conversion des colonnes numériques (NUMBER, FLOAT)
- Conversion des timestamps Unix en TIMESTAMP
- Gestion des booléens (remote_allowed, sponsored)
- Extraction des champs depuis les fichiers JSON

**Problème rencontré :** Les colonnes `remote_allowed` et `sponsored` contenaient des valeurs `1.0`/`0.0` au lieu de booléens → résolu avec `CASE WHEN`.

---

## Phase 3 : Couche Gold

Création de 5 vues agrégées pour les analyses.

**Problème rencontré :** La colonne `company_name` dans job_postings contenait des IDs numériques et non des noms → résolu en joingnant sur `company_id`.

---

## Analyses et Résultats

## Analyses et Résultats

### 1. Top 10 des titres de postes les plus publiés par industrie
![top10_titres](screenshots/titres de postes les plus publiés par industrie.png)

On observe que les postes les plus publiés varient fortement selon l'industrie. Dans l'IT, les postes techniques dominent, tandis que dans d'autres secteurs ce sont des postes commerciaux.

### 2. Top 10 des postes les mieux rémunérés par industrie
![top10_salaires](screenshots/postes les mieux rémunérés par industrie.png)

Les salaires les plus élevés se trouvent dans les secteurs technologiques et financiers.

### 3. Répartition des offres par taille d'entreprise
![taille_entreprise](screenshots/Répartition des offres par taille d'entreprise.png)

Les grandes entreprises (taille 7) publient nettement plus d'offres que les petites.

### 4. Répartition des offres par secteur d'activité
![secteur](screenshots/Répartition des offres par secteur d'activité.png)

Les secteurs les plus actifs en recrutement sont les ressources humaines et la technologie.

### 5. Répartition des offres par type d'emploi
![type_emploi](screenshots/Répartition des offres par type d'emploi.png)

Le temps plein (Full-time) domine largement avec plus de 12 000 offres.
---

## Technologies Utilisées

- Snowflake (SQL, Snowpark)
- Streamlit
- AWS S3 (bucket fourni, accès via Snowflake Stage)
