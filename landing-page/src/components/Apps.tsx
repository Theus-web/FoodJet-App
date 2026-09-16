import { ArrowUpRight, Building2, ChefHat, Smartphone } from "lucide-react";

const apps = [
 { name: "FoodJet Delivery", audience: "Para clientes.", icon: Smartphone, accent: "bg-[#F97316]", action: "Em breve na App Store e Google Play"},
 { name: "FoodJet Parceiro", audience: "Para restaurantes.", icon: Building2, accent: "bg-[#19212e]", action: "Em breve"},
 { name: "FoodJet Entregador", audience: "Para entregadores.", icon: ChefHat, accent: "bg-[#374151]", action: "Em breve"},
];

export function Apps() {
 return <section id="apps" className="section-space bg-[#111827] text-white"><div className="container"><div className="flex flex-col justify-between gap-5 md:flex-row md:items-end"><div><span className="eyebrow border-white/[.14] bg-white/[.08] text-[#ffb47a]">EM BREVE</span><h2 className="section-title mt-4 text-white">Tenha o FoodJet<br/><span className="text-[#ff9a52]">na palma da mão.</span></h2></div><p className="max-w-sm text-[15px] leading-6 text-[#cbd5e1]">Escolha a experiência que combina com você. Os aplicativos estarão disponíveis em breve.</p></div><div className="mt-10 grid gap-4 md:grid-cols-3">{apps.map(({name,audience,icon: Icon,accent,action}) => <article key={name} className="group relative overflow-hidden rounded-3xl border border-white/[.12] bg-white/[.06] p-6 transition-all duration-200 hover:-translate-y-1 hover:bg-white/[.09]"><div className={`grid size-12 place-items-center rounded-2xl ${accent} text-white shadow-lg`}><Icon className="size-5"/></div><h3 className="mt-8 text-[18px] font-extrabold tracking-tight">{name}</h3><p className="mt-1 text-sm text-white/60">{audience}</p><div className="mt-7 flex items-center justify-between rounded-xl border border-white/[.12] bg-black/[.12] px-3 py-2.5"><span className="text-[9px] font-bold text-white/60">{action}</span><ArrowUpRight className="size-4 text-[#ff9a52]"/></div></article>)}</div></div></section>
}
