import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";

// mostra: Anterior 1 ... 4 [5] 6 ... 12 Próxima
function paginasVisiveis(atual, total) {
  const set = new Set([1, total, atual - 1, atual, atual + 1]);
  const nums = [...set].filter((n) => n >= 1 && n <= total).sort((a, b) => a - b);
  const out = [];
  nums.forEach((n, i) => {
    if (i > 0 && n - nums[i - 1] > 1) out.push("...");
    out.push(n);
  });
  return out;
}

export default function Paginacao({ page, totalPages, onChange }) {
  return (
    <nav className="flex items-center justify-center gap-1" aria-label="Paginação">
      <Button variant="ghost" disabled={page <= 1} onClick={() => onChange(page - 1)}>
        <ChevronLeft className="mr-1 h-4 w-4" /> Anterior
      </Button>

      {paginasVisiveis(page, totalPages).map((p, i) =>
        p === "..." ? (
          <span key={`r${i}`} className="px-2 text-muted-foreground">…</span>
        ) : (
          <Button
            key={p}
            size="icon"
            variant={p === page ? "default" : "ghost"}
            onClick={() => onChange(p)}
            aria-current={p === page ? "page" : undefined}
          >
            {p}
          </Button>
        )
      )}

      <Button variant="ghost" disabled={page >= totalPages} onClick={() => onChange(page + 1)}>
        Próxima <ChevronRight className="ml-1 h-4 w-4" />
      </Button>
    </nav>
  );
}
