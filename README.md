# Editar Ordem de Serviço (base simples)

React + Vite + Tailwind + shadcn/ui (cliente) e Express (servidor, com dados mocados).

## Rodar

```bash
npm run install:all   # instala raiz, server e client
npm run dev           # sobe API (3001) e front (5173)
```

Abra http://localhost:5173

O servidor lê `server/.env` (PORT, CORS_ORIGIN, PAGE_SIZE). Existe um `server/.env.example` para commitar no Git.

## Estrutura

```
server/
  .env       -> PORT, CORS_ORIGIN, PAGE_SIZE
  mock.js    -> dados mocados (gerado dos .sql, 50 OS / times / equipamentos / usuários)
  index.js   -> rotas: GET /api/os?page=&limit=, GET/PUT /api/os/:id, GET /api/times, GET /api/equipamentos
scripts/
  gerar-mock.py -> regenera server/mock.js a partir dos .sql
client/src/
  App.jsx        -> lista de cards + paginação; abre o modal ao clicar num card
  OsCard.jsx     -> card de uma OS
  Paginacao.jsx  -> botões de página
  EditarOS.jsx   -> o modal de edição (form + chamadas à API)
  constantes.js  -> cores de prioridade/status e formatação de data
  components/ui/ -> componentes shadcn (button, input, select, dialog...)
```

Os nomes dos campos da API são os mesmos das colunas da tabela `os`
(os_titulo, os_descricao, prioridade, data_limite, id_time_responsavel),
então trocar o mock por MariaDB depois é só mexer no `server/index.js`.
