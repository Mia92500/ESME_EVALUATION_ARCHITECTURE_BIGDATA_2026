import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.title("Dashboard LinkedIn - Analyse des Offres d'Emploi")

# 1. Top 10 des titres de postes les plus publiés par industrie
st.header("Top 10 des titres de postes les plus publiés par industrie")
df1 = session.sql("SELECT * FROM LINKEDIN.GOLD.TOP10_TITRES_PAR_INDUSTRIE").to_pandas()
industrie1 = st.selectbox("Choisir une industrie", df1["INDUSTRY"].unique(), key="ind1")
df1_filtered = df1[df1["INDUSTRY"] == industrie1].sort_values("NB_OFFRES", ascending=False)
st.bar_chart(df1_filtered.set_index("TITLE")["NB_OFFRES"])

# 2. Top 10 des postes les mieux rémunérés par industrie
st.header("Top 10 des postes les mieux rémunérés par industrie")
df2 = session.sql("SELECT * FROM LINKEDIN.GOLD.TOP10_SALAIRES_PAR_INDUSTRIE").to_pandas()
industrie2 = st.selectbox("Choisir une industrie", df2["INDUSTRY"].unique(), key="ind2")
df2_filtered = df2[df2["INDUSTRY"] == industrie2].sort_values("SALAIRE_MOYEN", ascending=False)
st.bar_chart(df2_filtered.set_index("TITLE")["SALAIRE_MOYEN"])

# 3. Répartition des offres par taille d'entreprise
st.header("Répartition des offres par taille d'entreprise")
df3 = session.sql("SELECT * FROM LINKEDIN.GOLD.REPARTITION_TAILLE_ENTREPRISE").to_pandas()
st.bar_chart(df3.set_index("COMPANY_SIZE")["NB_OFFRES"])

# 4. Répartition des offres par secteur d'activité
st.header("Répartition des offres par secteur d'activité")
df4 = session.sql("SELECT * FROM LINKEDIN.GOLD.REPARTITION_SECTEUR").to_pandas()
st.bar_chart(df4.set_index("INDUSTRY")["NB_OFFRES"])

# 5. Répartition des offres par type d'emploi
st.header("Répartition des offres par type d'emploi")
df5 = session.sql("SELECT * FROM LINKEDIN.GOLD.REPARTITION_TYPE_EMPLOI").to_pandas()
st.bar_chart(df5.set_index("FORMATTED_WORK_TYPE")["NB_OFFRES"])
