import { CalendarDays, Users, User } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { PRIORIDADES, STATUS, formatarData } from "@/constantes";

// card de uma OS; clicar abre o modal de edição
export default function OsCard({ os, onClick }) {
  const prioridade = PRIORIDADES.find((p) => p.value === os.prioridade);
  const status = STATUS[os.os_status];

  return (
    <button
      type="button"
      onClick={onClick}
      className="flex h-full flex-col gap-3 rounded-xl border border-border bg-popover p-5 text-left transition-colors hover:border-primary focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
    >
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs text-muted-foreground">O.S. #{os.os_id}</span>
        <Badge className={status.cor}>{status.label}</Badge>
      </div>

      <div>
        <h3 className="font-semibold leading-tight">{os.os_titulo}</h3>
        <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{os.os_descricao}</p>
      </div>

      <div className="space-y-1.5 text-sm text-muted-foreground">
        <p className="flex items-center gap-2"><Users className="h-4 w-4" />{os.nome_time}</p>
        <p className="flex items-center gap-2"><User className="h-4 w-4" />{os.nome_criador}</p>
        <p className="flex items-center gap-2"><CalendarDays className="h-4 w-4" />{formatarData(os.data_limite)}</p>
      </div>

      <div className="mt-auto flex flex-wrap items-center gap-2 pt-2">
        <Badge className={prioridade.cor}>{prioridade.label}</Badge>
        {os.equipamentos.map((e) => (
          <span key={e.equipamento_id} className="rounded-full bg-primary/15 px-2.5 py-0.5 text-xs text-primary">
            {e.quantidade}x {e.nome_equipamento}
          </span>
        ))}
      </div>
    </button>
  );
}
