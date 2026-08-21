<img width="1920" height="1080" alt="Credit risk" src="https://github.com/user-attachments/assets/cb1dd443-d37c-44dc-8e80-94322f8a33b5" />

## Visão Geral do Projeto

Modelo de **Machine Learning para predição de inadimplência** que reduziu perdas financeiras em **R$ 32,5 milhões** e gerou **R$ 41,7 milhões em resultado adicional** mantendo a mesma taxa de aprovação de crédito.

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

**Prevenção de Data Leakage:** Apenas informações disponíveis até a data de referência são utilizadas.

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

[[26682   834]
 [  506  1433]]


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
 Percentual de Valor gerado a mais pelo modelo | 3% | | 
 Percentual de Redução de perdas do modelo   | 50% | | 
 Resultado financeiro        | —             | —                | —                |

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

text
Exploração → Feature Engineering → Feature Store → Treinamento → Avaliação → MLflow → Predição


---

## Stack Tecnológico

**Core:** Python, SQL, XGBoost, Pandas, Scikit-learn

**Plataforma:** Databricks (Spark, Feature Store, MLflow)

---

## Conclusão

Solução completa de **predição de inadimplência** com arquitetura Feature Store, prevenção de data leakage e avaliação de impacto financeiro.

> **Resultado:** Modelo XGBoost (AUC 0.9753) que **reduz perdas em R$ 32,5 milhões** e gera **3% de valor adicional**, mantendo 90,58% de aprovação e reduzindo inadimplência em **50%**.
