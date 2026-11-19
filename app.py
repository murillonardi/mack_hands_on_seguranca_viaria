import streamlit as st
import pandas as pd
import json
import urllib.request
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
import plotly.express as px

# --- Configuração da Página ---
st.set_page_config(
    page_title="Dashboard de Segurança Viária - SP",
    page_icon="🚗",
    layout="wide"
)

# --- Carregamento de Dados com Cache ---
@st.cache_data
def carregar_dados():
    df_features = pd.read_csv('refined_ml_features.csv', compression='gzip')
    df_local = pd.read_csv('dim_localizacao.csv', compression='gzip')
    df_fct = pd.read_csv('fct_acidente.csv', compression='gzip')
    df_tempo = pd.read_csv('dim_tempo.csv', compression='gzip')
    return df_features, df_local, df_fct, df_tempo

with st.spinner("Carregando e processando os dados do sistema..."):
    df_features, df_local, df_fct, df_tempo = carregar_dados()

# --- Mapeamento e Execução do K-Means com Nomes dos Clusters ---
@st.cache_data
def processar_clusters(df):
    cluster_nomes = {
        0: "0 - Interior Rural / Frota Antiga e Alta Letalidade",
        1: "1 - Urbano Médio / Conflito Moto x Carro",
        2: "2 - Metropolitano Rico / Mobilidade Ativa",
        3: "3 - Eixo Logístico / Baixa Renda e Subnotificação",
        4: "4 - Corredor Rodoviário Pesado"
    }

    if 'cluster' in df.columns:
        df['cluster_label'] = df['cluster'].map(cluster_nomes).fillna("Cluster " + df['cluster'].astype(str))
        return df
        
    colunas_modelo = [
        "taxa_acidentes_100k",
        "indice_fatalidade_proporcional_100k",
        "ipdm_geral",
        "pct_envolvem_motocicleta",
        "pct_acidente_primario_colisao"
    ]
    
    X = df[colunas_modelo].fillna(0)
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    kmeans = KMeans(n_clusters=5, random_state=42, n_init=10)
    df['cluster'] = kmeans.fit_predict(X_scaled)
    df['cluster_label'] = df['cluster'].map(cluster_nomes).fillna("Cluster " + df['cluster'].astype(str))
    return df

df_features = processar_clusters(df_features)

# Mapeando o nome do município
municipios_map = df_local[['cod_ibge', 'municipio']].drop_duplicates().set_index('cod_ibge')['municipio'].to_dict()
df_features['nome_municipio'] = df_features['cod_ibge'].map(municipios_map)

# Tratamento e agregação das coordenadas geográficas para o mapa
df_coords = df_local.dropna(subset=['latitude', 'longitude']).copy()
df_coords['lat'] = df_coords['latitude'].apply(lambda x: x / 1e7 if abs(x) > 1000 else x)
df_coords['lon'] = df_coords['longitude'].apply(lambda x: x / 1e7 if abs(x) > 1000 else x)

# Filtro para manter apenas os limites aproximados do Estado de São Paulo
df_coords = df_coords[(df_coords['lat'] >= -26) & (df_coords['lat'] <= -19) & (df_coords['lon'] >= -54) & (df_coords['lon'] <= -44)]
df_coords_agg = df_coords.groupby('cod_ibge')[['lat', 'lon']].mean().reset_index()

df_features = pd.merge(df_features, df_coords_agg, on='cod_ibge', how='left')

# --- Barra Lateral (Filtros) ---
anos_disponiveis = sorted([a for a in df_features['ano'].unique() if 2019 <= a <= 2024])

anos_selecionados = st.sidebar.multiselect(
    "Selecione o(s) Ano(s)", 
    options=anos_disponiveis, 
    default=anos_disponiveis
)

clusters_disponiveis = sorted(df_features['cluster_label'].unique())
clusters_selecionados = st.sidebar.multiselect("Filtrar por Clusters de Risco", clusters_disponiveis, default=clusters_disponiveis)

lista_municipios = sorted(df_features['nome_municipio'].dropna().unique())
municipios_selecionados = st.sidebar.multiselect("Filtrar por Município(s)", lista_municipios, default=[])

# Aplicando os filtros
df_filtrado = df_features[
    (df_features['ano'].isin(anos_selecionados)) & 
    (df_features['cluster_label'].isin(clusters_selecionados))
]

if municipios_selecionados:
    df_filtrado = df_filtrado[df_filtrado['nome_municipio'].isin(municipios_selecionados)]

# --- Cabeçalho do Dashboard ---
st.title("🚦 Dashboard Analítico de Segurança Viária e Clusters (SP)")
anos_str = ", ".join(map(str, anos_selecionados)) if anos_selecionados else "Nenhum selecionado"
st.markdown(f"Análise integrada de sinistros de trânsito e vulnerabilidade socioeconômica para o(s) ano(s): **{anos_str}**.")

# --- KPIs de Alto Nível (Indicadores Macro) ---
st.markdown("### 📊 Indicadores Gerais (Macro)")
col1, col2, col3 = st.columns(3)

with col1:
    total_municipios = df_filtrado['cod_ibge'].nunique()
    st.metric("Municípios Analisados", f"{total_municipios}")

with col2:
    media_ipdm = df_filtrado['ipdm_geral'].mean()
    st.metric("IPDM Médio", f"{media_ipdm:.2f}" if not pd.isna(media_ipdm) else "N/A")

with col3:
    media_taxa = df_filtrado['taxa_acidentes_100k'].mean()
    st.metric("Mortalidade (por 100k hab.)", f"{media_taxa:.1f}" if not pd.isna(media_taxa) else "N/A")

# --- KPIs de Veículos (Média de Envolvimento por Tipo) ---
st.markdown("### 🚗 % de Envolvimento em Acidentes por Tipo de Veículo")
col_v1, col_v2, col_v3, col_v4, col_v5 = st.columns(5)

with col_v1:
    media_carro = df_filtrado['pct_envolvem_carro'].mean() * 100 if 'pct_envolvem_carro' in df_filtrado.columns else 0
    st.metric("Carros", f"{media_carro:.1f}%")

with col_v2:
    media_moto = df_filtrado['pct_envolvem_motocicleta'].mean() * 100 if 'pct_envolvem_motocicleta' in df_filtrado.columns else 0
    st.metric("Motos", f"{media_moto:.1f}%")

with col_v3:
    media_caminhao = df_filtrado['pct_envolvem_caminhao'].mean() * 100 if 'pct_envolvem_caminhao' in df_filtrado.columns else 0
    st.metric("Caminhões", f"{media_caminhao:.1f}%")

with col_v4:
    media_onibus = df_filtrado['pct_envolvem_onibus'].mean() * 100 if 'pct_envolvem_onibus' in df_filtrado.columns else 0
    st.metric("Ônibus", f"{media_onibus:.1f}%")

with col_v5:
    media_bicicleta = df_filtrado['pct_envolvem_bicicleta'].mean() * 100 if 'pct_envolvem_bicicleta' in df_filtrado.columns else 0
    st.metric("Bicicletas", f"{media_bicicleta:.1f}%")

st.markdown("---")

# --- Carregamento do GeoJSON dos Municípios ---
@st.cache_data
def carregar_geojson():
    with open("geojs-35-mun.json", "r", encoding="utf-8") as f:
        return json.load(f)

geojson_sp = carregar_geojson()
df_filtrado['cod_ibge_str'] = df_filtrado['cod_ibge'].astype(str)

# --- Mapa Coroplético ---
st.subheader("🗺️ Mapa Coroplético: Limites Municipais por Perfil de Risco")
st.markdown("Áreas dos municípios do Estado de São Paulo pintadas de acordo com o **Perfil de Risco** atribuído.")

if not df_filtrado.empty:
    fig_map = px.choropleth(
        df_filtrado,
        geojson=geojson_sp,
        locations='cod_ibge_str',
        featureidkey="properties.id",
        color='cluster_label',
        hover_name='nome_municipio',
        hover_data=['taxa_acidentes_100k', 'ipdm_geral', 'indice_fatalidade_proporcional_100k'],
        color_discrete_map={
            "0 - Interior Rural / Frota Antiga e Alta Letalidade": "#d73027",
            "1 - Urbano Médio / Conflito Moto x Carro": "#fc8d59",
            "2 - Metropolitano Rico / Mobilidade Ativa": "#91cf60",
            "3 - Eixo Logístico / Baixa Renda e Subnotificação": "#fee08b",
            "4 - Corredor Rodoviário Pesado": "#4575b4"
        },
        projection="mercator",
        height=600
    )
    
    fig_map.update_geos(fitbounds="locations", visible=False)
    fig_map.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    
    st.plotly_chart(fig_map, use_container_width=True)
else:
    st.warning("Não há dados suficientes para exibir no mapa com os filtros selecionados.")

# --- Gráficos Complementares ---
col_A, col_B = st.columns(2)

with col_A:
    st.subheader("Relação: IPDM Geral vs. Taxa de Acidentes")
    df_scatter_clean = df_filtrado.dropna(subset=['ipdm_geral', 'taxa_acidentes_100k'])
    
    fig_scatter = px.scatter(
        df_scatter_clean,
        x='ipdm_geral',
        y='taxa_acidentes_100k',
        color='cluster_label',
        hover_name='nome_municipio',
        size='taxa_acidentes_100k',
        labels={'ipdm_geral': 'IPDM Geral', 'taxa_acidentes_100k': 'Taxa de Acidentes / 100k', 'cluster_label': 'Cluster'},
        template='plotly_white'
    )
    st.plotly_chart(fig_scatter, use_container_width=True)

with col_B:
    st.subheader("Taxa Média de Acidentes por Cluster")
    perfil_agg = df_filtrado.groupby('cluster_label')['taxa_acidentes_100k'].mean().reset_index()
    fig_bar = px.bar(
        perfil_agg,
        x='cluster_label',
        y='taxa_acidentes_100k',
        color='cluster_label',
        labels={'cluster_label': 'Cluster', 'taxa_acidentes_100k': 'Taxa Média de Acidentes / 100k'},
        template='plotly_white'
    )
    fig_bar.update_layout(xaxis_tickangle=-15)
    st.plotly_chart(fig_bar, use_container_width=True)

# --- GRÁFICO: Proporção de Acidentes Letais por Cluster ---
st.markdown("---")
st.subheader("⚠️ Proporção Média de Acidentes Letais por Cluster")
st.markdown("Comparativo do percentual de acidentes fatais e índice de fatalidade proporcional por perfil de risco.")

col_C, col_D = st.columns(2)

with col_C:
    if 'pct_acidentes_fatais' in df_filtrado.columns:
        perfil_letalidade = df_filtrado.groupby('cluster_label')['pct_acidentes_fatais'].mean().reset_index()
        fig_letalidade = px.bar(
            perfil_letalidade,
            x='cluster_label',
            y='pct_acidentes_fatais',
            color='cluster_label',
            labels={'cluster_label': 'Cluster', 'pct_acidentes_fatais': 'Média % de Acidentes Fatais'},
            template='plotly_white'
        )
        fig_letalidade.update_layout(xaxis_tickangle=-15)
        st.plotly_chart(fig_letalidade, use_container_width=True)
    else:
        st.info("Coluna de acidentes fatais não encontrada no DataFrame.")

with col_D:
    if 'indice_fatalidade_proporcional_100k' in df_filtrado.columns:
        perfil_fat_prop = df_filtrado.groupby('cluster_label')['indice_fatalidade_proporcional_100k'].mean().reset_index()
        fig_fat_prop = px.bar(
            perfil_fat_prop,
            x='cluster_label',
            y='indice_fatalidade_proporcional_100k',
            color='cluster_label',
            labels={'cluster_label': 'Cluster', 'indice_fatalidade_proporcional_100k': 'Índice de Fatalidade Proporcional / 100k'},
            template='plotly_white'
        )
        fig_fat_prop.update_layout(xaxis_tickangle=-15)
        st.plotly_chart(fig_fat_prop, use_container_width=True)
    else:
        st.info("Índice de fatalidade proporcional não encontrado no DataFrame.")

# --- NOVO GRÁFICO: Distribuição Temporal dos Acidentes por Perfil de Risco ---
st.markdown("---")
st.subheader("⏰ Distribuição Temporal dos Acidentes por Perfil de Risco")
st.markdown("Proporção média de ocorrências dividida por período do dia (**Manhã, Tarde, Noite e Madrugada**) em cada cluster.")

cols_periodos = ['pct_acidentes_manha', 'pct_acidentes_tarde', 'pct_acidentes_noite', 'pct_acidentes_madrugada']
if all(c in df_filtrado.columns for c in cols_periodos):
    df_melted = df_filtrado.melt(
        id_vars=['cluster_label'],
        value_vars=cols_periodos,
        var_name='Periodo',
        value_name='Percentual'
    )
    periodo_map = {
        'pct_acidentes_manha': 'Manhã',
        'pct_acidentes_tarde': 'Tarde',
        'pct_acidentes_noite': 'Noite',
        'pct_acidentes_madrugada': 'Madrugada'
    }
    df_melted['Periodo'] = df_melted['Periodo'].map(periodo_map)
    df_melted['Percentual'] = df_melted['Percentual'] * 100
    
    perfil_tempo = df_melted.groupby(['cluster_label', 'Periodo'])['Percentual'].mean().reset_index()
    
    fig_tempo = px.bar(
        perfil_tempo,
        x='cluster_label',
        y='Percentual',
        color='Periodo',
        barmode='group',
        labels={'cluster_label': 'Perfil de Risco', 'Percentual': 'Média (%)', 'Periodo': 'Período do Dia'},
        template='plotly_white'
    )
    fig_tempo.update_layout(xaxis_tickangle=-15, legend_title_text='Período do Dia')
    st.plotly_chart(fig_tempo, use_container_width=True)
else:
    st.info("Colunas de períodos temporais não encontradas no DataFrame.")

st.markdown("---")

# --- Análise de Impacto: Tipos de Acidentes e Gravidade ---
st.subheader("📋 Detalhamento Adicional: Tipos de Acidentes e Gravidade (Mortalidade)")
try:
    if 'ano' in df_fct.columns:
        df_fct_ano = df_fct[df_fct['ano'].isin(anos_selecionados)]
    elif 'id_tempo' in df_fct.columns and 'id_tempo' in df_tempo.columns:
        df_fct_tempo = pd.merge(df_fct, df_tempo, on='id_tempo', how='inner')
        df_fct_ano = df_fct_tempo[df_fct_tempo['ano'].isin(anos_selecionados)]
    else:
        df_fct_ano = df_fct.copy()

    colunas_possiveis_tipo = [c for c in df_fct_ano.columns if 'tipo' in c.lower() or 'acidente' in c.lower() or 'natureza' in c.lower()]
    colunas_possiveis_obito = [c for c in df_fct_ano.columns if 'obito' in c.lower()  or 'fatal' in c.lower() or 'mort' in c.lower() or 'vitima' in c.lower()]

    if colunas_possiveis_tipo and colunas_possiveis_obito:
        tipo_col = colunas_possiveis_tipo[0]
        obito_col = colunas_possiveis_obito[0]
        
        df_mortalidade = df_fct_ano.groupby(tipo_col).agg(
            total_acidentes=('id_acidente' if 'id_acidente' in df_fct_ano.columns else tipo_col, 'count'),
            total_obitos=(obito_col, 'sum')
        ).reset_index()
        
        df_mortalidade['taxa_mortalidade_pct'] = (df_mortalidade['total_obitos'] / df_mortalidade['total_acidentes']) * 100
        df_mortalidade = df_mortalidade.sort_values(by='total_obitos', ascending=False).head(10)

        fig_mortalidade = px.bar(
            df_mortalidade,
            x='total_obitos',
            y=tipo_col,
            orientation='h',
            text='total_obitos',
            color='total_obitos',
            labels={tipo_col: 'Tipo de Acidente', 'total_obitos': 'Total de Óbitos / Vitais'},
            template='plotly_white'
        )
        fig_mortalidade.update_layout(yaxis={'categoryorder':'total ascending'})
        st.plotly_chart(fig_mortalidade, use_container_width=True)
except Exception as e:
    st.warning(f"Não foi possível renderizar o gráfico detalhado de tipos de acidentes automaticamente: {e}.")

st.markdown("---")

# --- Tabela Detalhada ---
st.subheader("📋 Detalhamento dos Municípios no Filtro Atual")
st.dataframe(
    df_filtrado[['cod_ibge', 'nome_municipio', 'ano', 'cluster_label', 'ipdm_geral', 'taxa_acidentes_100k', 'indice_fatalidade_proporcional_100k']]
    .sort_values(by='taxa_acidentes_100k', ascending=False),
    use_container_width=True
)