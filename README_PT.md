<img width="1920" height="1080" alt="Credit risk" src="https://github.com/user-attachments/assets/cb1dd443-d37c-44dc-8e80-94322f8a33b5" />

> :information_source: Para a versão em inglês deste README, veja o arquivo **README.md**.

## Visão Geral do Projeto

Modelo de **Machine Learning para predição de inadimplência** que reduziu perdas financeiras em **R$ 32,5 milhões** e gerou **R$ 41,7 milhões em resultado adicional**, mantendo a mesma taxa de aprovação de crédito.

### Destaques

* **AUC-ROC: 0.9753** | **KS: 0.8497** — Forte poder discriminatório
* **50% menos inadimplência** entre clientes aprovados vs. política atual
* **29% de redução** na Loss Rate
* **+100 features** extraídas de histórico de pagamentos, dados cadastrais e comportamentais
* Desenvolvido no **Databricks** com **Feature Store** e **MLflow**

---

## Problema de Negócio

**Identificar clientes com maior risco de inadimplência** para reduzir perdas financeiras sem prejudicar a aprovação de bons clientes.

**Target:** Pagamento com 5+ dias de atraso em relação ao vencimento.

**Saída:** Probabilidade de inadimplência (0 a 1) para cada cobrança.

---

## Dados & Infraestrutura

### Execução no Databricks

Projeto desenvolvido no **Databricks** usando Feature Store, Spark e MLflow.

**Tabelas necessárias:**

* `credit_score.data.cadastral` — Perfil e dados cadastrais (1.315 clientes)
* `credit_score.data.info` — Informações financeiras mensais (24.401 registros)
* `credit_score.data.pagamentos` — Histórico de cobranças (77.414 registros)

---

## Solução

**Modelo XGBoost** com **+100 features** organizadas em Feature Store:

* Dados cadastrais e sociodemográficos
* Histórico de pagamentos (atrasos, antecipações, pontualidade)
* Padrões de renda e funcionários
* Variáveis temporais (janelas de 3, 6 e 12 meses)
* Características de cobranças

**Prevenção de Data Leakage:** Apenas informações disponíveis até a data de referência são utilizadas, e a base é dividida **cronologicamente** (60% treino / 20% validação / 20% teste) em vez de aleatoriamente, simulando um cenário real de crédito em que o modelo é treinado com o passado e aplicado ao futuro.

### Seleção do modelo

Três algoritmos de classificação foram comparados usando o mesmo pipeline de pré-processamento (tratamento de valores nulos com um `NullImputer` customizado, extração de variáveis de data, One-Hot Encoding e Min-Max Scaling), com cada experimento registrado no **MLflow**:

* **XGBoost** — modelo de boosting baseado em árvores
* **Regressão Logística** — baseline linear, usada como referência de interpretabilidade
* **Random Forest** — ensemble de árvores para relações não lineares

O **XGBoost** foi selecionado para o modelo final por apresentar o melhor desempenho de AUC-ROC/KS e boa generalização entre validação e teste.

---

## Desempenho do Modelo

O modelo final (**XGBoost**) foi avaliado em três conjuntos:

 Métrica    | Teste      |
 ---------- | ---------- |
 AUC-ROC    | **0.9753** |
 KS         | **0.8497** |

**Resultados no conjunto de teste:**

* AUC-ROC: **0.9753**
* F1-Score: **0.6814**
* Acurácia: **0.9545**
* Precisão: **0.6321**
* Recall: **0.7390**

**Matriz de confusão para threshold 0.27 no conjunto de teste:**

```
[[26682   834]
 [  506  1433]]
```

Resultados de validação e teste são próximos, indicando **boa capacidade de generalização**.

---

## Análise de Risco por Faixa de Score

Para verificar se a probabilidade representa diferentes níveis de risco, os clientes foram agrupados em faixas de score:

 Faixa de Score | Inadimplência Observada |
 -------------- | ----------------------: |
 0,00 – 0,10    |                    1%   |
 0,10 – 0,20    |                   24%   |
 0,20 – 0,30    |                   34%   |
 0,30 – 0,40    |                   40%   |
 0,40 – 0,50    |                   50%   |
 0,50 – 0,60    |                   56%   |
 0,60 – 1,00    |                   79%   |

Os resultados demonstram **relação clara entre score e inadimplência observada**, indicando excelente **capacidade de ordenação por risco**.

---

## Impacto Financeiro

Comparação entre modelo e política de crédito existente (proxy), ambos com **taxa de aprovação de 90,58%**:

 Indicador                   | Proxy         | Modelo           | Melhoria         |
 --------------------------- | ------------  | ---------------  | ---------------- |
 Taxa de aprovação           | 90,58%        | 90,58%           | —                |
 Inadimplência dos aprovados | 2,65%         | **1,36%**        | **-50%**         |
 Loss Rate                   | 1,91%         | **1,36%**        | **-29%**         |
 Valor aprovado              | 1.344.562.234 | **1.370.059.752**| +R$ 25.497.518   |
 Valor perdido               | 65.628.663    | **33.086.110**   | **-R$ 32.542.553**|

### Ganhos Estimados

Mantendo a mesma taxa de aprovação, o modelo entrega:

* **50% menos inadimplência** entre os aprovados
* **29% de redução** na Loss Rate
* **R$ 32,5 milhões a menos** em perdas
* **~3% de aumento** no valor gerado

O modelo seleciona uma carteira com **menor risco e menor perda financeira**.

---

## Principais Resultados

✓ **AUC 0.9753 / KS 0.8497** — Forte poder discriminatório

✓ **Score vs. Inadimplência:** 0,0-0,1 → 1% | 0,6-1,0 → 79%

✓ **Impacto financeiro:** +3% valor gerado, -50% inadimplência

✓ **Boa generalização** entre validação e teste

---

## Pipeline de Execução

```text
Exploração → Feature Engineering → Feature Store → Treinamento → Avaliação → MLflow → Predição
```

---

## Estrutura do Projeto

```text
credit_databricks/
├── LICENSE
├── requirements.txt
├── README.md                          # Versão em inglês
├── README_PT.md                       # Este arquivo
├── ENGLISH/
│   └── src/                           # Mesmo pipeline, documentado em inglês
│       └── ...
└── PORTUGUESE/
    └── src/
        ├── 01-initial_exploration/
        │   ├── 01_data_exploration.ipynb   # Exploração dos dados brutos
        │   └── 02-feature_store.ipynb      # Desenho da Feature Store
        ├── 02-feature_store/
        │   ├── fs_cadastral.sql            # Features cadastrais e sociodemográficas
        │   ├── fs_temporal.sql             # Features temporais
        │   ├── fs_historico_financeiro.sql # Features de histórico financeiro
        │   ├── fs_renda.sql                # Features de renda
        │   ├── fs_funcionarios.sql         # Features de funcionários
        │   ├── fs_historico_pagamentos.sql # Features de histórico de pagamentos
        │   └── ingestao.ipynb              # Cria/atualiza as tabelas da Feature Store
        └── 03-model_inad/
            ├── fl_inad.sql                 # Query que constrói a amostra rotulada (target)
            ├── train.ipynb                 # Seleção de modelo, treino, avaliação e MLflow
            └── predict.ipynb               # Carrega o modelo e escora novas cobranças
```

---

## Como Executar o Projeto

Este projeto roda no **Databricks**, utilizando **Unity Catalog**, **Feature Engineering (Feature Store)** e **MLflow**. Os passos abaixo assumem que você tem um workspace Databricks com um cluster ativo e acesso às tabelas de origem.

### 1. Importe o repositório para o Databricks

* No seu workspace Databricks, acesse **Workspace → Import** e envie o repositório (ou clone diretamente pelo **Repos**, caso use integração com Git).
* Associe os notebooks a um cluster com **Databricks Runtime for Machine Learning** (já vem com `pandas`, `numpy`, `scikit-learn`, `mlflow` e `scipy` pré-instalados).

### 2. Instale as dependências adicionais

Apenas duas bibliotecas extras são necessárias — elas são instaladas dentro dos próprios notebooks via `%pip install`, ou podem ser instaladas uma única vez no cluster:

```bash
pip install databricks-feature-engineering xgboost
```

### 3. Prepare as tabelas de origem

Certifique-se de que as seguintes tabelas existem no seu Unity Catalog (schema `credit_score.data`):

* `credit_score.data.cadastral`
* `credit_score.data.info`
* `credit_score.data.pagamentos`

### 4. Explore os dados (opcional)

Execute os notebooks em `PORTUGUESE/src/01-initial_exploration/` para entender os dados brutos e o desenho da Feature Store:

```text
01_data_exploration.ipynb
02-feature_store.ipynb
```

### 5. Construa a Feature Store

Execute `PORTUGUESE/src/02-feature_store/ingestao.ipynb`. Esse notebook lê cada query `fs_*.sql` e grava os resultados na Feature Store (`feature_store.credit_score.*`), particionada por `REF_DATE`, para a lista de datas de referência definida no notebook (ex.: `'2018-10'` até `'2021-06'` para o treinamento).

> :warning: Ajuste a lista `dates` dentro do notebook para o intervalo de datas de referência que deseja (re)processar. Executar novamente para uma data já processada faz merge/substitui os dados dessa data.

### 6. Treine o modelo

Execute `PORTUGUESE/src/03-model_inad/train.ipynb`. Esse notebook:

1. Constrói a amostra rotulada de treinamento a partir de `fl_inad.sql`, unida às tabelas da Feature Store via `FeatureLookup`;
2. Divide os dados **cronologicamente** em treino / validação / teste (60% / 20% / 20%);
3. Compara **XGBoost**, **Regressão Logística** e **Random Forest**, registrando cada execução no **MLflow**;
4. Retreina o pipeline final de **XGBoost** e o registra no MLflow, exibindo o `run_id` do modelo salvo.

> :information_source: Copie o `run_id` exibido — ele será necessário nas próximas etapas (células de avaliação dentro do `train.ipynb` e no `predict.ipynb`).

### 7. Ingira a data de referência mais recente

Após o treinamento, execute a seção **"Ingestão Final Antes da Predição"** ao final do `ingestao.ipynb`, atualizando a lista `dates` com a data de referência mais recente (ex.: `'2021-07'`), para que a Feature Store tenha as features atualizadas disponíveis para a predição.

### 8. Gere as previsões

Execute `PORTUGUESE/src/03-model_inad/predict.ipynb`, atualizando o `run_id` na célula de carregamento do modelo (`mlflow.sklearn.load_model("runs:/<run_id>/model")`) para o valor salvo no passo 6. O notebook:

1. Constrói o conjunto de predição para o `REF_DATE` mais recente, usando os mesmos `FeatureLookup`s do treinamento;
2. Escora cada registro com o modelo treinado (colunas `pred` e `proba`);
3. Cruza as predições com os pagamentos reais e calcula **AUC** e **KS** sobre esse lote mais recente, como verificação final antes de usar os scores em produção.

---

## Stack Tecnológico

**Core:** Python, SQL, XGBoost, Pandas, Scikit-learn

**Plataforma:** Databricks (Spark, Feature Store, MLflow, Unity Catalog)

---

## Conclusão

Solução completa de **predição de inadimplência** com arquitetura Feature Store, prevenção de data leakage e avaliação de impacto financeiro.

> **Resultado:** Modelo XGBoost (AUC 0.9753) que **reduz perdas em R$ 32,5 milhões** e gera **3% de valor adicional**, mantendo 90,58% de aprovação e reduzindo inadimplência em **50%**.
