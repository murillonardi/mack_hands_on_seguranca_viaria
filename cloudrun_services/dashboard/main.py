import streamlit as st
import pandas as pd
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

# --- Execução do K-Means na base de features (Município x Ano) ---
@st.cache_data
def rodar_kmeans(df):
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
    df['cluster_label'] = "Cluster " + df['cluster'].astype(str)
    return df

df_features = rodar_kmeans(df_features)

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
st.sidebar.header("🔍 Filtros de Análise")

anos_disponiveis = sorted(df_features['ano'].unique())
ano_selecionado = st.sidebar.selectbox("Selecione o Ano", anos_disponiveis, index=len(anos_disponiveis)-1)

clusters_disponiveis = sorted(df_features['cluster_label'].unique())
clusters_selecionados = st.sidebar.multiselect("Filtrar por Clusters de Risco", clusters_disponiveis, default=clusters_disponiveis)

# Filtro por Município
lista_municipios = sorted(df_features['nome_municipio'].dropna().unique())
municipios_selecionados = st.sidebar.multiselect("Filtrar por Município(s)", lista_municipios, default=[])

# Aplicando os filtros
df_filtrado = df_features[
    (df_features['ano'] == ano_selecionado) & 
    (df_features['cluster_label'].isin(clusters_selecionados))
]

if municipios_selecionados:
    df_filtrado = df_filtrado[df_filtrado['nome_municipio'].isin(municipios_selecionados)]

# --- Cabeçalho do Dashboard ---
st.title("🚦 Dashboard Analítico de Segurança Viária e Clusters (SP)")
st.markdown(f"Análise integrada de sinistros de trânsito e vulnerabilidade socioeconômica para o ano de **{ano_selecionado}**.")

# --- KPIs de Alto Nível ---
col1, col2, col3, col4 = st.columns(4)

with col1:
    total_municipios = df_filtrado['cod_ibge'].nunique()
    st.metric("Municípios Analisados", f"{total_municipios}")

with col2:
    media_ipdm = df_filtrado['ipdm_geral'].mean()
    st.metric("IPDM Médio", f"{media_ipdm:.2f}" if not pd.isna(media_ipdm) else "N/A")

with col3:
    media_taxa = df_filtrado['taxa_acidentes_100k'].mean()
    st.metric("Taxa Média (por 100k hab.)", f"{media_taxa:.1f}" if not pd.isna(media_taxa) else "N/A")

with col4:
    media_moto = df_filtrado['pct_envolvem_motocicleta'].mean() * 100
    st.metric("% Envolvimento com Motos", f"{media_moto:.1f}%" if not pd.isna(media_moto) else "N/A")

st.markdown("---")

# --- Mapa Geográfico do Estado de São Paulo ---
st.subheader("🗺️ Mapa de Distribuição dos Municípios e Clusters no Estado de São Paulo")
st.markdown("Visualização geográfica dos municípios coloridos de acordo com o **Cluster de Risco** atribuído.")

if not df_filtrado.dropna(subset=['lat', 'lon']).empty:
    fig_map = px.scatter_geo(
        df_filtrado.dropna(subset=['lat', 'lon']),
        lat='lat',
        lon='lon',
        color='cluster_label',
        hover_name='nome_municipio',
        hover_data=['taxa_acidentes_100k', 'ipdm_geral', 'indice_fatalidade_proporcional_100k'],
        projection="mercator",
        height=500,
        labels={'cluster_label': 'Cluster'}
    )
    fig_map.update_geos(
        fitbounds="locations",
        visible=True,
        lonaxis_range=[-53.5, -44.0],
        lataxis_range=[-25.5, -19.5]
    )
    fig_map.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    st.plotly_chart(fig_map, use_container_width=True)
else:
    st.warning("Não há dados geográficos suficientes para exibir no mapa com os filtros selecionados.")

st.markdown("---")

# --- Layout de Gráficos Complementares ---
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
    st.plotly_chart(fig_bar, use_container_width=True)

# --- Seção Inferior: Tabela Detalhada ---
st.subheader("📋 Detalhamento dos Municípios no Filtro Atual")
st.dataframe(
    df_filtrado[['cod_ibge', 'nome_municipio', 'ano', 'cluster_label', 'ipdm_geral', 'taxa_acidentes_100k', 'indice_fatalidade_proporcional_100k']]
    .sort_values(by='taxa_acidentes_100k', ascending=False),
    use_container_width=True
)
