<img width="1920" height="1080" alt="Credit risk" src="https://github.com/user-attachments/assets/cb1dd443-d37c-44dc-8e80-94322f8a33b5" />

## Visão Geral do Projeto

Modelo de **Machine Learning para predição de inadimplência** que reduziu perdas financeiras em **R$ 23,2 milhões** e gerou **R$ 33,7 milhões em resultado adicional** mantendo a mesma taxa de aprovação de crédito.

### Destaques

* **AUC-ROC: 0.9748** | **KS: 0.8497** — Forte poder discriminatório
* **53% menos inadimplência** entre clientes aprovados vs. política atual
* **34% de redução** na Loss Rate
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

| Métrica | Treino | Validação | Teste      |
| ------- | ------ | --------- | ---------- |
| AUC-ROC | 0.9964 | 0.9759    | **0.9748** |
| KS      | 0.9437 | 0.8471    | **0.8497** |

**Resultados no conjunto de teste:**

* AUC-ROC: **0.9748**
* KS: **0.8497**
* F1-Score: **0.6703**
* Acurácia: **95.74%**
* Precisão: **68.62%**
* Recall: **65.52%**

Resultados de validação e teste são próximos, indicando **boa capacidade de generalização**.

---

## Análise de Risco por Faixa de Score

Para verificar se a probabilidade representa diferentes níveis de risco, os clientes foram agrupados em faixas de score:

| Faixa de Score | Inadimplência Observada |
| -------------- | ----------------------: |
| 0,00 – 0,10    |                    1%   |
| 0,10 – 0,20    |                   24%   |
| 0,20 – 0,30    |                   34%   |
| 0,30 – 0,40    |                   40%   |
| 0,40 – 0,50    |                   50%   |
| 0,50 – 0,60    |                   56%   |
| 0,60 – 1,00    |                   79%   |

Os resultados demonstram **relação clara entre score e inadimplência observada**, indicando excelente **capacidade de ordenação por risco**.

---

## Impacto Financeiro

Comparação entre modelo e política de crédito existente (proxy), ambos com **taxa de aprovação de 90,23%**:

| Indicador                   | Proxy       | Modelo          | Melhoria       |
| --------------------------- | ----------- | --------------- | -------------- |
| Taxa de aprovação           | 90,23%      | 90,23%          | —              |
| Inadimplência dos aprovados | 2,64%       | **1,23%**       | **-53%**       |
| Loss Rate                   | 1,99%       | **1,20%**       | **-34%**       |
| Valor aprovado              | R$ 1,346 bi | **R$ 1,359 bi** | +R$ 13 mi      |
| Valor perdido               | R$ 67,1 mi  | **R$ 43,9 mi**  | **-R$ 23,2 mi**|
| Resultado financeiro        | R$ 1,293 bi | **R$ 1,327 bi** | **+R$ 33,7 mi**|

### Ganhos Estimados

Mantendo a mesma taxa de aprovação, o modelo entrega:

* **53% menos inadimplência** entre os aprovados
* **34% de redução** na Loss Rate
* **R$ 23,2 milhões a menos** em perdas
* **R$ 33,7 milhões** de resultado financeiro adicional
* **~3% de aumento** no valor gerado

O modelo seleciona uma carteira com **menor risco e menor perda financeira**.

---

## Principais Resultados

✓ **AUC 0.9748 / KS 0.8497** — Forte poder discriminatório

✓ **Score vs. Inadimplência:** 0,0-0,1 → 1% | 0,6-1,0 → 79%

✓ **Impacto financeiro:** +R$ 33,7 mi e -53% inadimplência

✓ **Boa generalização** entre validação e teste

---



## Pipeline de Execução

```text
Exploração → Feature Engineering → Feature Store → Treinamento → Avaliação → MLflow → Predição
```

---

## Stack Tecnológico

**Core:** Python, SQL, XGBoost, Pandas, Scikit-learn

**Plataforma:** Databricks (Spark, Feature Store, MLflow)

---

## Conclusão

Solução completa de **predição de inadimplência** com arquitetura Feature Store, prevenção de data leakage e avaliação de impacto financeiro.

> **Resultado:** Modelo XGBoost (AUC 0.9748) que **reduz perdas em R$ 23,2 milhões** e gera **R$ 33,7 milhões adicionais**, mantendo 90,23% de aprovação e reduzindo inadimplência em **53%**.
