# Documentação Técnica do Banco de Dados

**Projeto AV3-BDR — Estrutura de Tabelas, Chaves e Restrições**

| Campo | Valor |
|---|---|
| **Repositório** | github.com/kersilva/AV3-BDR |
| **Banco de dados** | MariaDB / MySQL (schema `API2`) |
| **Engine** | InnoDB |
| **Charset / Collation** | utf8mb4 / utf8mb4_unicode_ci |
| **Versão do documento** | 1.0 |
| **Data de emissão** | 24 de novembro de 2026 |
| **Proprietário** | Equipe de Engenharia de Dados |

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Convenções e Padronização](#2-convenções-e-padronização)
3. [Modelo de Relacionamentos](#3-modelo-de-relacionamentos)
4. [Tabelas de Cadastro](#4-tabelas-de-cadastro)
   - 4.1 [usuarios](#41-usuarios)
   - 4.2 [time](#42-time)
   - 4.3 [equipamentos](#43-equipamentos)
5. [Tabelas de Processos](#5-tabelas-de-processos)
   - 5.1 [os](#51-os)
   - 5.2 [projetos](#52-projetos)
   - 5.3 [manutencoes](#53-manutencoes)
6. [Tabelas Vinculadas a Anexos e Itens](#6-tabelas-vinculadas-a-anexos-e-itens)
   - 6.1 [anexo](#61-anexo)
   - 6.2 [item_equipamento_os](#62-item_equipamento_os)
   - 6.3 [item_equipamento_projeto](#63-item_equipamento_projeto)
   - 6.4 [item_equipamento_manutencao](#64-item_equipamento_manutencao)
7. [Tabelas de Notificações](#7-tabelas-de-notificações)
   - 7.1 [notificacoes](#71-notificacoes)
   - 7.2 [notificacao_leituras](#72-notificacao_leituras)
8. [Tabelas de Histórico](#8-tabelas-de-histórico)
   - 8.1 [historico_registros](#81-historico_registros)
   - 8.2 [historico_os](#82-historico_os)
9. [Objetos de Banco Complementares](#9-objetos-de-banco-complementares)
10. [Considerações Finais](#10-considerações-finais)

---

## 1. Visão Geral

Este documento descreve a estrutura do banco de dados do projeto **AV3-BDR**, aplicação web para gestão de Ordens de Serviço (OS), Projetos e Manutenções. O banco foi implementado em MariaDB/MySQL sob o schema **API2**, utilizando o engine **InnoDB** (suporte a transações e chaves estrangeiras) e charset **utf8mb4** com collation **utf8mb4_unicode_ci**, garantindo compatibilidade com caracteres acentuados e emojis.

O schema é composto por **14 tabelas** distribuídas em quatro blocos principais: cadastros básicos (usuarios, times, equipamentos); processos operacionais (OS, projetos, manutenções); tabelas de apoio e relacionamento (anexos, itens de equipamento); e infraestrutura transversal (notificações e histórico). Completam o modelo 3 views, 7 procedures, 6 funções e 6 triggers responsáveis por auditoria e automações.

---

## 2. Convenções e Padronização

As convenções adotadas no projeto são:

- **Nomenclatura:** nomes de tabelas e colunas em _snake_case_, em português.
- **Chaves primárias:** coluna identidade com sufixo `_id` (ex.: `os_id`), tipo `INT AUTO_INCREMENT`.
- **Chaves estrangeiras:** prefixo `fk_` e nome descritivo da relação (ex.: `fk_criador_os`).
- **Índices:** prefixo `idx_` seguido da tabela e coluna (ex.: `idx_os_status`).
- **Datas de criação:** coluna `data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP` presente nas tabelas transacionais.
- **Integridade referencial:** uso de `ON DELETE SET NULL` em referências opcionais e `ON DELETE CASCADE` em dependentes.

---

## 3. Modelo de Relacionamentos

O diagrama entidade-relacionamento possui **usuarios** e **time** como núcleo organizacional, com relacionamento circular (um usuário pertence a um time; um time possui um responsável que é usuário). A partir desse núcleo derivam-se três frentes operacionais: **os** (ordens de serviço), **projetos** e **manutencoes**, todas referenciando o criador/responsável e o time executor.

**Tabela 1 — Cardinalidades principais entre entidades**

| Relacionamento | Coluna FK | Constraint | Descrição |
|---|---|---|---|
| usuarios (1) ↔ (N) os | `id_criador` | `fk_criador_os` | Um usuário cria várias OS |
| time (1) ↔ (N) os | `id_time_responsavel` | `fk_os_time` | Time executa várias OS |
| usuarios (1) ↔ (1) time | `responsavel_id` | `fk_time_responsavel` | Responsável pelo time |
| usuarios (1) ↔ (N) time | `time_id` | `fk_usuario_time` | Lotação do usuário |
| projetos (1) ↔ (N) os | `projeto_id` | `fk_os_projeto` | OS vinculadas a um projeto |
| manutencoes (1) ↔ (N) os | `manutencao_id` | `fk_os_manutencao` | OS vinculadas a manutenção |
| equipamentos (N) ↔ (N) os | `os_id + equipamento_id` | `item_equipamento_os` | Itens por OS |
| usuarios (1) ↔ (N) notificacoes | `usuario_origem_id` | `fk_notificacao_usuario` | Autor da notificação |
| os (1) ↔ (N) historico_os | `os_id` | FK (sem nome) | Auditoria de OS |

---

## 4. Tabelas de Cadastro

### 4.1 usuarios

Armazena as contas de acesso ao sistema. Cada usuário possui cargo, lotação em um time (opcional) e flag de ativação. O hash de senha é mantido em coluna própria, nunca trafegado pelas APIs.

**Tabela 2 — Estrutura da tabela `usuarios`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `id_usuario` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `nome` | VARCHAR(100) | NÃO | — | Nome completo do usuário |
| `email` | VARCHAR(150) | NÃO | — | E-mail único para login |
| `cargo` | ENUM(8 valores) | NÃO | — | superusuario\|gestor\|comercial\|suporte\|producao\|software\|implantacao\|monitoramento |
| `senha_hash` | VARCHAR(255) | NÃO | — | Hash da senha (bcrypt/argon2) |
| `ativo` | BOOLEAN | NÃO | TRUE | Indica se a conta está ativa |
| `time_id` | INT | SIM | NULL | FK → time(id_time); SET NULL on delete |
| `data_criacao` | DATETIME | NÃO | CURRENT_TIMESTAMP | Data de cadastro |

- **Chave primária:** `id_usuario`
- **FK:** `fk_usuario_time` → `time(id_time)` ON DELETE SET NULL ON UPDATE CASCADE
- **Únicos:** `email`
- **Índice:** `idx_usuarios_time(time_id)`

### 4.2 time

Representa equipes internas (ex.: Software, Produção, Implantação, Monitoramento). Cada time possui um responsável que também é um usuário, gerando dependência circular resolvida por `ALTER TABLE` após a criação das duas tabelas.

**Tabela 3 — Estrutura da tabela `time`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `id_time` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `nome_time` | VARCHAR(100) | NÃO | — | Nome único do time |
| `email_time` | VARCHAR(150) | SIM | NULL | E-mail institucional do time (único) |
| `departamento` | VARCHAR(100) | NÃO | — | Departamento organizacional |
| `responsavel_id` | INT | SIM | NULL | FK → usuarios(id_usuario); SET NULL |

- **Chave primária:** `id_time`
- **FK:** `fk_time_responsavel` → `usuarios(id_usuario)` ON DELETE SET NULL ON UPDATE CASCADE
- **Únicos:** `nome_time`, `email_time`
- **Índice:** `idx_time_responsavel(responsavel_id)`

### 4.3 equipamentos

Catálogo simples de equipamentos/material utilizado nas OS, projetos e manutenções. Por ser uma tabela de domínio, mantém apenas o nome único do item.

**Tabela 4 — Estrutura da tabela `equipamentos`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `equipamento_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `nome_equipamento` | VARCHAR(150) | NÃO | — | Nome único do equipamento |

- **Chave primária:** `equipamento_id`
- **Únicos:** `nome_equipamento`
- **FK:** nenhuma (tabela raiz de domínio)

---

## 5. Tabelas de Processos

### 5.1 os

Núcleo operacional do sistema: registra Ordens de Serviço. Cada OS possui status controlado por workflow, prioridade, prazo e vínculo opcional a um projeto ou a uma manutenção (mutuamente exclusivos em nível de aplicação).

**Tabela 5 — Estrutura da tabela `os`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `os_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `os_titulo` | VARCHAR(150) | NÃO | — | Título resumido da OS |
| `os_descricao` | TEXT | NÃO | — | Descrição detalhada |
| `os_status` | ENUM(6 valores) | NÃO | aberta | aberta\|em andamento\|concluida\|teste\|bloqueado\|review |
| `prioridade` | ENUM(4 valores) | NÃO | media | baixa\|media\|alta\|critica |
| `data_limite` | DATE | NÃO | — | Prazo de conclusão |
| `id_criador` | INT | NÃO | — | FK → usuarios(id_usuario) |
| `id_time_responsavel` | INT | SIM | NULL | FK → time(id_time); SET NULL |
| `projeto_id` | INT | SIM | NULL | FK → projetos(projeto_id); CASCADE |
| `manutencao_id` | INT | SIM | NULL | FK → manutencoes(manutencao_id); CASCADE |
| `data_criacao` | DATETIME | NÃO | CURRENT_TIMESTAMP | Data de abertura |

- **Chave primária:** `os_id`
- **FKs:**
  - `fk_criador_os` → `usuarios(id_usuario)`
  - `fk_os_time` → `time(id_time)` ON DELETE SET NULL
  - `fk_os_projeto` → `projetos(projeto_id)` ON DELETE CASCADE
  - `fk_os_manutencao` → `manutencoes(manutencao_id)` ON DELETE CASCADE
- **Índices:** `idx_os_criador`, `idx_os_time`, `idx_os_projeto`, `idx_os_manutencao`, `idx_os_status`

### 5.2 projetos

Gerencia projetos comerciais/técnicos com datas contratuais, tipo de sistema e responsável técnico. Possui também vendedor para rastreabilidade comercial.

**Tabela 6 — Estrutura da tabela `projetos`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `projeto_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `nome` | VARCHAR(150) | NÃO | — | Nome do projeto |
| `data_assinatura_contrato` | DATE | SIM | NULL | Data de assinatura |
| `data_implantacao` | DATE | SIM | NULL | Data prevista de implantação |
| `data_vencimento_contrato` | DATE | SIM | NULL | Vencimento do contrato |
| `data_limite` | DATE | SIM | NULL | Prazo interno de entrega |
| `responsavel_id` | INT | SIM | NULL | FK → usuarios(id_usuario); SET NULL |
| `vendedor_id` | INT | SIM | NULL | FK → usuarios(id_usuario); SET NULL |
| `tipo_sistema` | VARCHAR(100) | NÃO | — | Classificação do sistema |
| `prioridade` | ENUM(4) | NÃO | media | baixa\|media\|alta\|critica |
| `status` | ENUM(3) | NÃO | aberto | aberto\|em_andamento\|finalizado |
| `descricao` | TEXT | SIM | NULL | Descrição livre |
| `data_criacao` | DATETIME | NÃO | CURRENT_TIMESTAMP | Cadastro do projeto |

- **Chave primária:** `projeto_id`
- **FKs:**
  - `fk_projeto_responsavel` → `usuarios(id_usuario)` ON DELETE SET NULL
  - `fk_projeto_vendedor` → `usuarios(id_usuario)` ON DELETE SET NULL
- **Índices:** `idx_projeto_responsavel`, `idx_projeto_vendedor`

### 5.3 manutencoes

Registra demandas de manutenção sobre sistemas/projetos existentes. Permite classificação por tipo (corretiva, preventiva, evolutiva, adaptativa) e possui status próprio independente das OS vinculadas.

**Tabela 7 — Estrutura da tabela `manutencoes`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `manutencao_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `data_inicio_problema` | DATE | NÃO | — | Quando o problema foi detectado |
| `tipo_manutencao` | ENUM(4) | NÃO | — | corretiva\|preventiva\|evolutiva\|adaptativa |
| `descricao_situacao` | TEXT | NÃO | — | Detalhamento do problema |
| `status` | ENUM(4) | NÃO | aberta | aberta\|em andamento\|concluida\|cancelada |
| `data_criacao` | DATETIME | NÃO | CURRENT_TIMESTAMP | Cadastro |
| `projeto_id` | INT | SIM | NULL | FK → projetos(projeto_id); SET NULL |
| `resumo` | VARCHAR(255) | SIM | NULL | Resumo curto |
| `responsavel_id` | INT | SIM | NULL | FK → usuarios(id_usuario); SET NULL |
| `data_limite` | DATE | SIM | NULL | Prazo |
| `prioridade` | ENUM(4) | NÃO | media | baixa\|media\|alta\|critica |

- **Chave primária:** `manutencao_id`
- **FKs:**
  - `fk_manutencao_projeto` → `projetos(projeto_id)` ON DELETE SET NULL
  - `fk_manutencao_responsavel` → `usuarios(id_usuario)` ON DELETE SET NULL
- **Índices:** `idx_manutencao_projeto`, `idx_manutencao_responsavel`

---

## 6. Tabelas Vinculadas a Anexos e Itens

### 6.1 anexo

Armazena arquivos binários vinculados a uma OS, projeto ou manutenção. A regra de negócio garante que cada anexo esteja vinculado a exatamente uma entidade, controlada por _check constraint_.

**Tabela 8 — Estrutura da tabela `anexo`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `anexo_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `os_id` | INT | SIM | NULL | FK → os(os_id); CASCADE |
| `nome_anexo` | VARCHAR(255) | NÃO | — | Nome do arquivo |
| `anexo_tipo` | VARCHAR(150) | NÃO | — | MIME type |
| `anexo_tamanho` | BIGINT UNSIGNED | SIM | NULL | Tamanho em bytes |
| `data_anexo` | DATETIME | NÃO | CURRENT_TIMESTAMP | Upload |
| `manutencao_id` | INT | SIM | NULL | FK → manutencoes(manutencao_id); CASCADE |
| `projeto_id` | INT | SIM | NULL | FK → projetos(projeto_id); CASCADE |
| `conteudo_arquivo` | LONGBLOB | NÃO | — | Binário do arquivo |

- **Chave primária:** `anexo_id`
- **FKs:** `fk_anexos_os`, `fk_anexo_manutencao`, `fk_anexo_projeto` (todas ON DELETE CASCADE)
- **Constraint CHECK (`chk_anexo_um_vinculo`):** exatamente um entre `os_id`, `manutencao_id` e `projeto_id` deve ser não nulo
- **Índices:** `idx_anexo_os`, `idx_anexo_manutencao`, `idx_anexo_projeto`

### 6.2 item_equipamento_os

Tabela associativa N:N entre **os** e **equipamentos**, registrando os itens consumidos em cada ordem de serviço.

**Tabela 9 — Estrutura da tabela `item_equipamento_os`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `os_id` | INT | NÃO | — | PK composta; FK → os(os_id); CASCADE |
| `equipamento_id` | INT | NÃO | — | PK composta; FK → equipamentos(equipamento_id); CASCADE |
| `quantidade` | INT | NÃO | 1 | Quantidade utilizada |

- **Chave primária:** (`os_id`, `equipamento_id`)
- **FKs:** `fk_item_os`, `fk_item_os_equipamento`
- **Constraint CHECK (`chk_item_os_quantidade`):** `quantidade > 0`

### 6.3 item_equipamento_projeto

Associação N:N entre **projetos** e **equipamentos**, com mesma estrutura da tabela anterior.

**Tabela 10 — Estrutura da tabela `item_equipamento_projeto`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `projeto_id` | INT | NÃO | — | PK composta; FK → projetos(projeto_id); CASCADE |
| `equipamento_id` | INT | NÃO | — | PK composta; FK → equipamentos(equipamento_id); CASCADE |
| `quantidade` | INT | NÃO | 1 | Quantidade prevista |

- **Chave primária:** (`projeto_id`, `equipamento_id`)
- **FKs:** `fk_item_projeto`, `fk_item_projeto_equipamento`
- **Constraint CHECK (`chk_item_projeto_quantidade`):** `quantidade > 0`

### 6.4 item_equipamento_manutencao

Associação N:N entre **manutencoes** e **equipamentos**, com mesma estrutura das demais.

**Tabela 11 — Estrutura da tabela `item_equipamento_manutencao`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `manutencao_id` | INT | NÃO | — | PK composta; FK → manutencoes(manutencao_id); CASCADE |
| `equipamento_id` | INT | NÃO | — | PK composta; FK → equipamentos(equipamento_id); CASCADE |
| `quantidade` | INT | NÃO | 1 | Quantidade utilizada |

- **Chave primária:** (`manutencao_id`, `equipamento_id`)
- **FKs:** `fk_item_manutencao`, `fk_item_manutencao_equipamento`
- **Constraint CHECK (`chk_item_manutencao_quantidade`):** `quantidade > 0`

---

## 7. Tabelas de Notificações

### 7.1 notificacoes

Mensagens emitidas pelo sistema ou por usuários, dirigidas a um time. Podem estar vinculadas a uma OS específica (opcional) e registrar o usuário de origem.

**Tabela 12 — Estrutura da tabela `notificacoes`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `notificacao_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `titulo` | VARCHAR(150) | NÃO | — | Título curto |
| `mensagem` | VARCHAR(200) | NÃO | — | Corpo da mensagem |
| `time_id` | INT | NÃO | — | FK → time(id_time); CASCADE |
| `os_id` | INT | SIM | NULL | FK → os(os_id); SET NULL |
| `usuario_origem_id` | INT | SIM | NULL | FK → usuarios(id_usuario); SET NULL |
| `data_criacao` | DATETIME | NÃO | CURRENT_TIMESTAMP | Envio |

- **Chave primária:** `notificacao_id`
- **FKs:**
  - `fk_notificacao_time` (CASCADE)
  - `fk_notificacao_os` (SET NULL)
  - `fk_notificacao_usuario` (SET NULL)
- **Índices:** `idx_notificacoes_time`, `idx_notificacoes_os`, `idx_notificacoes_data`

### 7.2 notificacao_leituras

Registra quais usuários leram cada notificação e em que momento. Funciona como tabela de controle de leitura, com chave composta.

**Tabela 13 — Estrutura da tabela `notificacao_leituras`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `notificacao_id` | INT | NÃO | — | PK composta; FK → notificacoes(notificacao_id); CASCADE |
| `usuario_id` | INT | NÃO | — | PK composta; FK → usuarios(id_usuario); CASCADE |
| `data_leitura` | DATETIME | NÃO | CURRENT_TIMESTAMP | Momento da leitura |

- **Chave primária:** (`notificacao_id`, `usuario_id`)
- **FKs:** `fk_leitura_notificacao` (CASCADE), `fk_leitura_usuario` (CASCADE)

---

## 8. Tabelas de Histórico

### 8.1 historico_registros

Auditoria genérica de tabelas (atualmente alimentada por triggers em **projetos**). Armazena snapshot JSON do registro alterado, o tipo de ação e o usuário responsável (id e e-mail).

**Tabela 14 — Estrutura da tabela `historico_registros`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `historico_id` | BIGINT AUTO_INCREMENT | NÃO | — | Chave primária |
| `tabela` | VARCHAR(64) | NÃO | — | Nome da tabela auditada |
| `registro_id` | VARCHAR(100) | NÃO | — | PK do registro (como string) |
| `tipo_acao` | ENUM(3) | NÃO | — | criado\|atualizado\|deletado |
| `dados` | JSON | NÃO | — | Snapshot do registro em JSON |
| `usuario_id` | INT | SIM | NULL | Usuário autor (sem FK) |
| `usuario_email` | VARCHAR(150) | SIM | NULL | E-mail do autor |
| `data_historico` | DATETIME | NÃO | CURRENT_TIMESTAMP | Momento da alteração |

- **Chave primária:** `historico_id`
- **FKs:** nenhuma (tabela de auditoria isolada)
- **Índices:** `idx_historico_tabela_registro (tabela, registro_id)`, `idx_historico_data`

### 8.2 historico_os

Auditoria específica de Ordens de Serviço, alimentada por triggers `trg_insert_os`, `trg_update_os` e `trg_delete_os`. Armazena snapshot dos campos relevantes da OS a cada evento.

**Tabela 15 — Estrutura da tabela `historico_os`**

| Campo | Tipo | Nulo | Padrão | Descrição |
|---|---|---|---|---|
| `historico_id` | INT AUTO_INCREMENT | NÃO | — | Chave primária |
| `usuario_id` | INT | SIM | NULL | Usuário autor (sem FK) |
| `usuario_email` | VARCHAR(150) | SIM | NULL | E-mail do autor |
| `data_historico` | DATETIME | NÃO | CURRENT_TIMESTAMP | Momento do evento |
| `tipo_acao` | ENUM(3) | NÃO | — | criado\|atualizado\|deletado |
| `os_id` | INT | NÃO | — | OS alvo do evento |
| `id_time_responsavel` | INT | SIM | NULL | FK → time(id_time); SET NULL |
| `os_titulo` | VARCHAR(150) | NÃO | — | Snapshot do título |
| `os_status` | ENUM(6) | NÃO | aberta | Snapshot do status |
| `data_limite` | DATE | NÃO | — | Snapshot do prazo |

- **Chave primária:** `historico_id`
- **FK:** `id_time_responsavel` → `time(id_time)` ON DELETE SET NULL ON UPDATE CASCADE
- Demais colunas `usuario_id` e `os_id` não possuem FK para evitar ciclos com triggers

---

## 9. Objetos de Banco Complementares

Além das tabelas, o schema **API2** possui objetos de automação e leitura que suportam auditoria, relatórios e regras de negócio. A relação abaixo resume esses objetos para fins de rastreabilidade, sem descrever suas assinaturas em detalhe.

**Tabela 16 — Views, procedures, funções e triggers do schema**

| Tipo | Nome | Finalidade |
|---|---|---|
| VIEW | `vw_os_detalhadas` | OS com dados de criador, time, projeto e manutenção |
| VIEW | `vw_resumo_times` | Total de OS por time (concluídas e abertas) |
| VIEW | `vw_projetos_detalhados` | Projetos com responsável e total de OS |
| PROCEDURE | `prc_os_por_status` | Conta OS agrupadas por status |
| PROCEDURE | `prc_os_por_time` | Conta OS agrupadas por time |
| PROCEDURE | `prc_atualizar_status_os` | Atualiza status de uma OS |
| PROCEDURE | `prc_transferir_os` | Transfere OS entre times |
| PROCEDURE | `buscar_os_por_periodo` | Lista OS por intervalo de datas |
| PROCEDURE | `consultar_historico_os` | Consulta histórico de uma OS |
| PROCEDURE | `prc_relatorio_cursor` | Relatório com uso de cursor |
| FUNCTION | `dias_para_prazo` | Dias restantes até a `data_limite` |
| FUNCTION | `percentual_conclusao` | Percentual de OS concluídas |
| FUNCTION | `contar_os_usuario` | Total de OS por usuário |
| FUNCTION | `quantidade_os_equipe` | Total de OS por equipe |
| FUNCTION | `quantidade_alteracoes` | Quantidade de alterações em registro |
| FUNCTION | `taxa_conclusao` | Taxa de conclusão de OS |
| TRIGGER | `trg_insert_os` | Insere em `historico_os` após INSERT |
| TRIGGER | `trg_update_os` | Insere em `historico_os` após UPDATE |
| TRIGGER | `trg_delete_os` | Insere em `historico_os` após DELETE |
| TRIGGER | `trg_insert_projeto` | Insere em `historico_registros` após INSERT |
| TRIGGER | `trg_update_projeto` | Insere em `historico_registros` após UPDATE |
| TRIGGER | `trg_delete_projeto` | Insere em `historico_registros` após DELETE |

---

## 10. Considerações Finais

A estrutura do banco de dados do projeto AV3-BDR segue boas práticas de modelagem relacional: uso consistente de chaves primárias _surrogate_, integridade referencial via `FOREIGN KEY` com ação declarada em `ON DELETE`, índices seletivos por coluna de busca, `CHECK` constraints em tabelas associativas e auditoria automatizada por triggers. A separação entre **historico_registros** (genérico, baseado em JSON) e **historico_os** (específico, colunado) permite flexibilidade sem prejudicar a performance de consultas recorrentes sobre OS.

**Recomendações de evolução:**

1. Padronizar o nome das PKs (algumas tabelas usam `id_*`, outras `*_id`).
2. Revisar a ausência de FK em `historico_os.os_id` e `historico_registros.usuario_id`, avaliando impacto de integridade versus performance das triggers.
3. Documentar assinaturas de procedures e functions em versão futura deste documento.

**Proprietário do documento:** Equipe de Engenharia de Dados
**Repositório-fonte:** github.com/kersilva/AV3-BDR (branch main, diretório `/database`, arquivos `script.sql` e `seed.sql`)
