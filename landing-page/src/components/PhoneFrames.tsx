import { Bell, Check, ChevronRight, Clock3, MapPin, Navigation, PackageCheck, Search, ShoppingBag, Star, Utensils } from "lucide-react";

export function CustomerPhone({ compact = false }: { compact?: boolean }) {
  return (
    <div className={`phone-shell ${compact ? "scale-[.88] origin-bottom sm:scale-100" : ""}`}>
      <div className="phone-notch" />
      <div className="phone-screen bg-[#fffaf7] px-3.5 pb-4 pt-8">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[9px] font-semibold text-[#6b7280]">Olá, que tal hoje?</p>
            <p className="text-[12px] font-bold text-[#111827]">Seu momento começa aqui</p>
          </div>
          <span className="grid size-7 place-items-center rounded-full bg-white text-[#111827] shadow-sm"><Bell className="size-3.5" /></span>
        </div>
        <div className="mt-3 flex items-center gap-2 rounded-xl bg-white px-2.5 py-2 shadow-sm ring-1 ring-black/[.04]">
          <Search className="size-3.5 text-[#9ca3af]" />
          <span className="text-[9px] text-[#9ca3af]">O que você quer pedir?</span>
        </div>
        <div className="mt-4 flex gap-2 overflow-hidden">
          {["Almoço", "Lanches", "Pizza"].map((item, index) => (
            <span key={item} className={`rounded-lg px-2.5 py-1.5 text-[8px] font-bold ${index === 0 ? "bg-[#F97316] text-white" : "bg-[#ffe8d7] text-[#b94f0a]"}`}>{item}</span>
          ))}
        </div>
        <div className="mt-4 overflow-hidden rounded-2xl bg-[#19212e] p-3 text-white shadow-lg">
          <div className="flex items-start justify-between">
            <div><p className="text-[8px] text-white/60">Próximo de você</p><p className="mt-0.5 text-[11px] font-bold">Sabores da região</p></div>
            <Utensils className="size-5 text-[#ffb47a]" />
          </div>
          <div className="mt-3 h-10 rounded-xl bg-[linear-gradient(120deg,#f97316,#ffb47a)] opacity-90" />
        </div>
        <p className="mt-4 text-[10px] font-extrabold text-[#111827]">Seu pedido</p>
        <div className="mt-2 rounded-2xl bg-white p-2.5 shadow-sm ring-1 ring-black/[.04]">
          <div className="flex items-center gap-2">
            <span className="grid size-7 place-items-center rounded-lg bg-[#fff0e7] text-[#F97316]"><ShoppingBag className="size-3.5" /></span>
            <div className="flex-1"><p className="text-[8px] font-bold text-[#111827]">Pedido confirmado</p><p className="text-[7px] text-[#6b7280]">Acompanhe cada etapa</p></div>
            <ChevronRight className="size-3 text-[#9ca3af]" />
          </div>
        </div>
      </div>
    </div>
  );
}

export function CourierPhone() {
  return (
    <div className="phone-shell phone-shell-dark">
      <div className="phone-notch" />
      <div className="phone-screen bg-[#19212e] px-3.5 pb-4 pt-8 text-white">
        <div className="flex items-center justify-between"><span className="text-[10px] font-bold">FoodJet <span className="text-[#F97316]">Entregador</span></span><span className="size-2 rounded-full bg-[#22c55e] shadow-[0_0_0_4px_rgba(34,197,94,.12)]" /></div>
        <p className="mt-4 text-[9px] text-white/55">Olá, sua próxima entrega</p>
        <div className="mt-2 rounded-2xl bg-white p-3 text-[#111827] shadow-[0_14px_30px_rgba(0,0,0,.18)]">
          <div className="flex items-center justify-between"><span className="rounded-full bg-[#eaf9ef] px-2 py-1 text-[7px] font-extrabold text-[#16803c]">NOVA ENTREGA</span><Clock3 className="size-3.5 text-[#F97316]" /></div>
          <p className="mt-3 text-[11px] font-bold">Retirada disponível</p>
          <p className="mt-1 text-[8px] leading-relaxed text-[#6b7280]">Confira os detalhes e siga para o restaurante.</p>
          <button className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-xl bg-[#F97316] py-2 text-[9px] font-bold text-white"><Navigation className="size-3" /> Ver rota</button>
        </div>
        <div className="mt-3 rounded-2xl border border-white/10 bg-white/[.06] p-3"><div className="flex gap-2"><MapPin className="mt-0.5 size-3.5 text-[#ff9a52]" /><div><p className="text-[8px] font-bold">Organize sua rotina</p><p className="mt-1 text-[7px] leading-relaxed text-white/55">Acompanhe suas entregas em um só lugar.</p></div></div></div>
        <div className="mt-4 flex items-center gap-2 text-[8px] text-white/60"><PackageCheck className="size-3.5 text-[#22c55e]" /> Pronto para começar</div>
      </div>
    </div>
  );
}

export function PartnerDashboard() {
  return (
    <div className="dashboard-shell">
      <div className="dashboard-nav"><div className="font-display text-sm font-extrabold tracking-[-.07em] text-white">Food<span className="text-[#F97316]">Jet</span></div><span className="rounded-lg bg-white/10 px-2 py-1 text-[7px] font-semibold text-white/60">Parceiro</span></div>
      <div className="dashboard-body">
        <div className="flex items-start justify-between"><div><p className="text-[8px] text-[#6b7280]">Operação</p><p className="text-[14px] font-extrabold tracking-tight text-[#111827]">Pedidos do dia</p></div><span className="grid size-8 place-items-center rounded-xl bg-[#fff0e7] text-[#F97316]"><Bell className="size-3.5" /></span></div>
        <div className="mt-4 grid grid-cols-3 gap-2">{["Novos", "Em preparo", "Finalizados"].map((item, i) => <div key={item} className={`rounded-xl p-2 ${i === 0 ? "bg-[#F97316] text-white" : "bg-[#f3f4f6] text-[#4b5563]"}`}><p className="text-[7px] font-semibold opacity-70">{item}</p><div className="mt-3 h-1.5 rounded-full bg-current opacity-30" /></div>)}</div>
        <div className="mt-3 rounded-2xl border border-[#e5e7eb] p-3"><div className="flex items-center justify-between"><div className="flex items-center gap-2"><span className="grid size-7 place-items-center rounded-lg bg-[#fff0e7] text-[#F97316]"><Utensils className="size-3.5" /></span><div><p className="text-[8px] font-bold text-[#111827]">Novo pedido</p><p className="text-[7px] text-[#9ca3af]">Atualizado agora</p></div></div><span className="rounded-full bg-[#eaf9ef] px-2 py-1 text-[7px] font-bold text-[#16803c]">Recebido</span></div><div className="mt-3 flex items-center justify-between rounded-lg bg-[#f9fafb] px-2 py-2 text-[7px] text-[#6b7280]"><span>Confirmar preparo</span><Check className="size-3 text-[#22c55e]" /></div></div>
      </div>
    </div>
  );
}

export function OrderStatus() {
  return <div className="order-status"><div className="flex items-center gap-2"><span className="grid size-7 place-items-center rounded-full bg-[#eaf9ef] text-[#22c55e]"><Check className="size-3.5" strokeWidth={3}/></span><div><p className="text-[8px] font-bold text-[#111827]">Pedido confirmado</p><p className="text-[7px] text-[#6b7280]">Acompanhe em tempo real</p></div></div><div className="mt-3 flex gap-1"><span className="h-1 flex-1 rounded-full bg-[#F97316]"/><span className="h-1 flex-1 rounded-full bg-[#F97316]"/><span className="h-1 flex-1 rounded-full bg-[#d1d5db]"/></div></div>;
}
