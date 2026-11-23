// valores dos ENUMs da tabela os
export const PRIORIDADES = [
  { value: "baixa", label: "Baixa", cor: "bg-green-600" },
  { value: "media", label: "Média", cor: "bg-yellow-600" },
  { value: "alta", label: "Alta", cor: "bg-orange-600" },
  { value: "critica", label: "Crítica", cor: "bg-red-600" },
];

export const STATUS = {
  aberta: { label: "Aberta", cor: "bg-blue-600" },
  "em andamento": { label: "Em andamento", cor: "bg-yellow-600" },
  concluida: { label: "Concluída", cor: "bg-green-600" },
  teste: { label: "Teste", cor: "bg-purple-600" },
  bloqueado: { label: "Bloqueado", cor: "bg-red-600" },
  review: { label: "Review", cor: "bg-cyan-700" },
};

// '2026-12-02' -> '02/12/2026'
export function formatarData(iso) {
  const [a, m, d] = iso.split("-");
  return `${d}/${m}/${a}`;
}
