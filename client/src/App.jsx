import { useEffect, useState } from "react";
import EditarOS from "./EditarOS.jsx";
import OsCard from "./OsCard.jsx";
import Paginacao from "./Paginacao.jsx";

export default function App() {
  const [page, setPage] = useState(1);
  const [lista, setLista] = useState(null); // { data, total, totalPages }
  const [osSelecionada, setOsSelecionada] = useState(null); // null = modal fechado

  // busca a página atual na API
  function carregar() {
    fetch(`/api/os?page=${page}`)
      .then((r) => r.json())
      .then(setLista);
  }

  useEffect(carregar, [page]);

  return (
    <main className="mx-auto max-w-6xl space-y-6 p-6">
      <header className="flex items-end justify-between">
        <h1 className="text-2xl font-semibold">Ordens de Serviço</h1>
        {lista && <span className="text-sm text-muted-foreground">{lista.total} registros</span>}
      </header>

      {!lista ? (
        <p className="text-muted-foreground">Carregando...</p>
      ) : (
        <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {lista.data.map((os) => (
              <OsCard key={os.os_id} os={os} onClick={() => setOsSelecionada(os.os_id)} />
            ))}
          </div>
          <Paginacao page={lista.page} totalPages={lista.totalPages} onChange={setPage} />
        </>
      )}

      {/* modal começa fechado; abre quando uma OS é clicada */}
      <EditarOS
        osId={osSelecionada}
        open={osSelecionada !== null}
        onOpenChange={(aberto) => !aberto && setOsSelecionada(null)}
        onSaved={carregar}
      />
    </main>
  );
}
