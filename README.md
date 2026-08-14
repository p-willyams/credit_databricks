
## Visão Geral do Projeto

Este projeto desenvolve uma **solução de Machine Learning para estimar a probabilidade de inadimplência** em cobranças mensais realizadas aos clientes. O objetivo é apoiar **decisões mais seguras de concessão de crédito e prevenção de perdas financeiras**.

A inadimplência é definida como **pagamento realizado com 5 ou mais dias de atraso** em relação à data de vencimento.

O modelo utiliza diferentes fontes de informação dos clientes:

* Histórico de pagamentos
* Dados cadastrais
* Informações financeiras mensais
* Histórico de comportamento
* Características temporais

A solução foi desenvolvida no **Databricks** e utiliza **Feature Store / Feature Engineering** para organização das variáveis e **MLflow** para registro e versionamento do modelo.

---

## Problema de Negócio

O principal objetivo é **identificar clientes com maior probabilidade de inadimplência**, permitindo apoiar decisões relacionadas ao risco de crédito e prevenção de perdas financeiras.

Principais desafios abordados:

* Identificação precoce de clientes de alto risco
* Utilização de histórico temporal dos clientes
* Criação de variáveis temporais consistentes
* Prevenção de vazamento de informação (*data leakage*)
* Avaliação da capacidade de discriminação do modelo
* Comparação com política de crédito existente
* Mensuração do impacto financeiro da solução

A variável target é binária:

```text
Inadimplente = 1 → Pagamento com 5+ dias de atraso
Inadimplente = 0 → Pagamento com menos de 5 dias de atraso
```

**A saída final do modelo é uma probabilidade contínua entre 0 e 1**, não uma classificação binária.

---

## Fonte de Dados

### Requisito: Databricks

Este projeto **deve ser executado no Databricks**. Os dados estão disponíveis como tabelas no ambiente e o projeto utiliza recursos específicos da plataforma:

* Databricks Tables
* Spark
* Feature Engineering / Feature Store
* Feature Lookup
* MLflow

### Tabelas Necessárias

Três bases principais contendo informações cadastrais, financeiras e comportamentais:

| Tabela                         | Descrição                          | Granularidade      | Registros |
| ------------------------------ | ---------------------------------- | ------------------ | --------- |
| `credit_score.data.cadastral`  | Informações cadastrais e de perfil | Cliente            | 1.315     |
| `credit_score.data.info`       | Informações financeiras mensais    | Cliente × Mês      | 24.401    |
| `credit_score.data.pagamentos` | Cobranças e pagamentos             | Cliente × Cobrança | 77.414    |

**Chaves de relacionamento:**

* `ID_CLIENTE` — identificador único do cliente
* `SAFRA_REF` — período de referência
* `ID_DOCUMENTO` — identificador único de cada cobrança

**Não é necessário** realizar download ou armazenamento local das bases.

---

## Solução

Foi desenvolvido um **modelo de classificação binária usando XGBoost** com mais de **100 features**, incluindo:

* Dados cadastrais (região, porte, segmento)
* Padrões comportamentais (renda, funcionários)
* Histórico de pagamentos (atrasos, antecipações, pontualidade)
* Variáveis temporais (janelas de 3, 6 e 12 meses)
* Características de cobranças (valores, prazos)

### Arquitetura Feature Store

As features são organizadas em tabelas separadas por finalidade:

| Feature Store                 | Conteúdo                    |
| ----------------------------- | --------------------------- |
| `fs_cadastral`                | Informações cadastrais      |
| `fs_temporal`                 | Características temporais   |
| `fs_historico_financeiro`     | Histórico financeiro        |
| `fs_renda`                    | Comportamento da renda      |
| `fs_funcionarios`             | Histórico de funcionários   |
| `fs_historico_pagamentos`     | Comportamento de pagamentos |

### Prevenção de Data Leakage

Por se tratar de um problema **temporal**, apenas informações disponíveis até `DATA_REF` são utilizadas na construção das features:

```text
Histórico disponível → DATA_REF → Apenas informações anteriores
```

Informações futuras (pagamentos ou alterações ainda não realizados) **não participam** da construção das features.

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

## Matriz de Confusão (Threshold = 0,34)

```text
                 Previsto 0  Previsto 1
Real 0 (Adimplente)  26.922       584
Real 1 (Inadimplente)   672     1.277
```

* **True Positives:** 1.277
* **False Negatives:** 672
* **False Positives:** 584
* **True Negatives:** 26.922

---

## Principais Resultados

O modelo final apresenta:

✓ **Forte poder discriminatório** (AUC = 0,9748 / KS = 0,8497)

✓ **Excelente ordenação por risco** (score 0,0-0,1 → 1% inadimplência vs. 0,6-1,0 → 79%)

✓ **Impacto financeiro significativo** (+R$ 33,7 mi vs. política atual)

✓ **Boa generalização** (desempenho consistente entre validação e teste)

✓ **Prevenção de data leakage** (features temporais construídas corretamente)

---

## Recomendação Prática

Usar o **score de probabilidade como filtro de triagem de risco** para priorizar prevenção de perdas. Para aprovação final de crédito, recomenda-se threshold mais conservador para balancear volume de aprovação e rentabilidade.

**A saída final do modelo é a probabilidade de inadimplência (0 a 1)**, não uma decisão binária.

---

## Fluxo de Execução

Ordem recomendada de execução:

```text
1.  Exploração dos dados
2.  Preparação dos dados
3.  Construção das Features (queries SQL)
4.  Ingestão no Feature Store
5.  Construção do Training Set (Feature Lookup)
6.  Treinamento dos modelos
7.  Avaliação e comparação
8.  Seleção do modelo final (XGBoost)
9.  Análise de Threshold
10. Análise Financeira
11. Registro do modelo no MLflow
12. Ingestão final do Feature Store
13. Geração de Predições
```

### Estrutura de Features (SQL)

```text
feature_store/
├── fs_cadastral.sql
├── fs_temporal.sql
├── fs_historico_financeiro.sql
├── fs_renda.sql
├── fs_funcionarios.sql
└── fs_historico_pagamentos.sql
```

---

## Tecnologias Utilizadas

* **Python** — linguagem principal
* **SQL** — construção de features
* **Pandas / NumPy** — manipulação de dados
* **Scikit-learn** — pré-processamento e avaliação
* **XGBoost** — algoritmo de modelagem
* **PySpark** — processamento distribuído
* **Databricks** — plataforma de execução
* **Feature Engineering / Feature Store** — gestão de features
* **MLflow** — registro e versionamento de modelos
* **Git** — controle de versão

---

## Conclusão

Este projeto demonstra uma **abordagem completa para predição de inadimplência**, combinando Machine Learning, engenharia de dados e avaliação financeira.

A solução incorpora:

✓ Exploração e tratamento de dados

✓ Engenharia de features temporais

✓ Arquitetura Feature Store

✓ Prevenção rigorosa de data leakage

✓ Modelo XGBoost otimizado

✓ Registro e versionamento com MLflow

✓ Análise de risco por faixa de score

✓ Otimização de threshold

✓ Comparação com política existente

✓ Avaliação de impacto financeiro

✓ Pipeline de previsão no Databricks

> **Em resumo:** O modelo gera uma probabilidade de inadimplência para cada cobrança e permite ordenar os clientes por risco, apresentando **potencial para melhorar a qualidade da carteira sem reduzir a taxa de aprovação**, com ganho estimado de **R$ 33,7 milhões** em relação à política atual.
