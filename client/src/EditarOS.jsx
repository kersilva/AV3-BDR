import { useEffect, useState } from "react";
import { X } from "lucide-react";
import { Dialog, DialogContent, DialogTitle, DialogDescription, DialogClose } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { PRIORIDADES } from "@/constantes";
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select";

function Obrigatorio() {
  return <span className="text-red-500"> *</span>;
}

export default function EditarOS({ osId, open, onOpenChange, onSaved }) {
  const [form, setForm] = useState(null); // dados da OS
  const [times, setTimes] = useState([]);
  const [catalogo, setCatalogo] = useState([]); // todos os equipamentos
  const [busca, setBusca] = useState("");
  const [salvando, setSalvando] = useState(false);
  const [mensagem, setMensagem] = useState("");

  // carrega tudo quando o modal abre
  useEffect(() => {
    if (!open) return;
    setMensagem("");
    Promise.all([
      fetch(`/api/os/${osId}`).then((r) => r.json()),
      fetch("/api/times").then((r) => r.json()),
      fetch("/api/equipamentos").then((r) => r.json()),
    ]).then(([os, times, equipamentos]) => {
      setForm(os);
      setTimes(times);
      setCatalogo(equipamentos);
    });
  }, [open, osId]);

  // atualiza um campo do form
  function mudar(campo, valor) {
    setForm((f) => ({ ...f, [campo]: valor }));
  }

  // adiciona equipamento (se já existe, soma +1 na quantidade)
  function adicionarEquipamento(eq) {
    setForm((f) => {
      const existe = f.equipamentos.find((e) => e.equipamento_id === eq.equipamento_id);
      const equipamentos = existe
        ? f.equipamentos.map((e) => (e === existe ? { ...e, quantidade: e.quantidade + 1 } : e))
        : [...f.equipamentos, { ...eq, quantidade: 1 }];
      return { ...f, equipamentos };
    });
    setBusca("");
  }

  function removerEquipamento(id) {
    setForm((f) => ({ ...f, equipamentos: f.equipamentos.filter((e) => e.equipamento_id !== id) }));
  }

  async function salvar(e) {
    e.preventDefault();
    setSalvando(true);
    setMensagem("");
    const resp = await fetch(`/api/os/${osId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    setSalvando(false);
    if (resp.ok) {
      onOpenChange(false);
      onSaved?.(); // avisa a lista para recarregar
    }
    else setMensagem((await resp.json()).erro || "Erro ao salvar");
  }

  // sugestões da busca de equipamentos
  const sugestoes = busca.trim()
    ? catalogo.filter((c) => c.nome_equipamento.toLowerCase().includes(busca.toLowerCase()))
    : [];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogTitle>Editar Ordem de Serviço</DialogTitle>
        <DialogDescription className="sr-only">Formulário de edição da ordem de serviço</DialogDescription>

        {!form ? (
          <p className="py-10 text-muted-foreground">Carregando...</p>
        ) : (
          <form onSubmit={salvar} className="mt-8 space-y-6">
            {/* título + prioridade */}
            <div className="grid gap-6 md:grid-cols-[1fr_215px]">
              <div className="space-y-2">
                <Label htmlFor="titulo">Título da O.S.<Obrigatorio /></Label>
                <Input id="titulo" required value={form.os_titulo} onChange={(e) => mudar("os_titulo", e.target.value)} />
              </div>

              <div className="space-y-2">
                <Label>Prioridade<Obrigatorio /></Label>
                <Select value={form.prioridade} onValueChange={(v) => mudar("prioridade", v)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {PRIORIDADES.map((p) => (
                      <SelectItem key={p.value} value={p.value}>
                        <Badge className={p.cor}>{p.label}</Badge>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* time + prazo */}
            <div className="grid gap-6 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Time responsável<Obrigatorio /></Label>
                <Select
                  value={String(form.id_time_responsavel ?? "")}
                  onValueChange={(v) => mudar("id_time_responsavel", Number(v))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Selecione um time" />
                  </SelectTrigger>
                  <SelectContent>
                    {times.map((t) => (
                      <SelectItem key={t.id_time} value={String(t.id_time)}>
                        {t.nome_time}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="prazo">Prazo / Data limite<Obrigatorio /></Label>
                <Input id="prazo" type="date" required value={form.data_limite} onChange={(e) => mudar("data_limite", e.target.value)} />
              </div>
            </div>

            {/* descrição */}
            <div className="space-y-2">
              <Label htmlFor="descricao" className="text-foreground">Descrição</Label>
              <Textarea id="descricao" className="min-h-[130px]" value={form.os_descricao} onChange={(e) => mudar("os_descricao", e.target.value)} />
            </div>

            {/* equipamentos */}
            <div className="space-y-2">
              <Label htmlFor="busca" className="text-foreground">Equipamentos e materiais (opcional)</Label>
              <div className="relative">
                <Input
                  id="busca"
                  autoComplete="off"
                  placeholder="Buscar equipamentos e materiais"
                  value={busca}
                  onChange={(e) => setBusca(e.target.value)}
                />
                {sugestoes.length > 0 && (
                  <ul className="absolute z-10 mt-1 w-full overflow-hidden rounded-lg border border-border bg-popover p-1 shadow-md">
                    {sugestoes.map((s) => (
                      <li key={s.equipamento_id}>
                        <button
                          type="button"
                          onClick={() => adicionarEquipamento(s)}
                          className="w-full rounded-md px-3 py-2 text-left text-sm hover:bg-accent"
                        >
                          {s.nome_equipamento}
                        </button>
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="flex flex-wrap gap-2 pt-1">
                {form.equipamentos.map((e) => (
                  <span
                    key={e.equipamento_id}
                    className="inline-flex items-center gap-1.5 rounded-full bg-primary/15 px-3 py-1 text-xs text-primary"
                  >
                    {e.quantidade}x {e.nome_equipamento}
                    <button type="button" onClick={() => removerEquipamento(e.equipamento_id)} aria-label="Remover">
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
            </div>

            {mensagem && <p className="text-sm text-red-400">{mensagem}</p>}

            {/* botões */}
            <div className="flex justify-end gap-3 pt-2">
              <DialogClose asChild>
                <Button type="button" variant="outline">Cancelar</Button>
              </DialogClose>
              <Button type="submit" disabled={salvando}>
                {salvando ? "Salvando..." : "Salvar Alterações"}
              </Button>
            </div>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
