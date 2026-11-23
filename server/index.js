import "dotenv/config"; // carrega o server/.env
import express from "express";
import cors from "cors";
import { usuarios, times, equipamentos, ordens } from "./mock.js";

const PORT = process.env.PORT || 3001;
const PAGE_SIZE = Number(process.env.PAGE_SIZE) || 9;

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN }));
app.use(express.json());

// listas para os selects / busca
app.get("/api/times", (req, res) => res.json(times));
app.get("/api/equipamentos", (req, res) => res.json(equipamentos));

// lista de OS paginada: GET /api/os?page=1&limit=9
app.get("/api/os", (req, res) => {
  const limit = Math.max(1, Number(req.query.limit) || PAGE_SIZE);
  const totalPages = Math.max(1, Math.ceil(ordens.length / limit));
  const page = Math.min(Math.max(1, Number(req.query.page) || 1), totalPages);

  const data = ordens.slice((page - 1) * limit, page * limit).map((o) => ({
    ...o,
    // equivalente aos JOINs da view vw_os_detalhadas
    nome_time: times.find((t) => t.id_time === o.id_time_responsavel)?.nome_time ?? null,
    nome_criador: usuarios.find((u) => u.id_usuario === o.id_criador)?.nome ?? null,
  }));

  res.json({ data, page, limit, total: ordens.length, totalPages });
});

// buscar uma OS
app.get("/api/os/:id", (req, res) => {
  const os = ordens.find((o) => o.os_id === Number(req.params.id));
  if (!os) return res.status(404).json({ erro: "OS não encontrada" });
  res.json(os);
});

// editar uma OS (só altera o array em memória, nada é salvo em banco)
app.put("/api/os/:id", (req, res) => {
  const os = ordens.find((o) => o.os_id === Number(req.params.id));
  if (!os) return res.status(404).json({ erro: "OS não encontrada" });

  const { os_titulo, os_descricao, prioridade, data_limite, id_time_responsavel, equipamentos } = req.body;

  if (!os_titulo || !prioridade || !data_limite || !id_time_responsavel) {
    return res.status(400).json({ erro: "Preencha os campos obrigatórios" });
  }

  Object.assign(os, { os_titulo, os_descricao, prioridade, data_limite, id_time_responsavel, equipamentos });
  res.json(os);
});

app.listen(PORT, () => console.log(`API rodando em http://localhost:${PORT}`));
