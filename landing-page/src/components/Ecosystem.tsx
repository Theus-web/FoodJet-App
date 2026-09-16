import { Bike, ChevronDown, ChevronRight, CookingPot, MapPin, Smartphone } from "lucide-react";

const nodes = [
 {label: "Cliente", icon: Smartphone, text: "Descobre e pede"}, {label: "FoodJet", icon: MapPin, text: "Conecta cada etapa", active: true}, {label: "Restaurante", icon: CookingPot, text: "Recebe e prepara"}, {label: "Entregador", icon: Bike, text: "Leva até você"},
];

export function Ecosystem() {
 return <section id="ecossistema" className="section-space bg-white"><div className="container"><div className="mx-auto max-w-2xl text-center"><span className="eyebrow">UM ECOSSISTEMA</span><h2 className="section-title mt-4">Todas as partes do delivery.<br/><span className="text-[#F97316]">Uma única plataforma.</span></h2><p className="section-copy mx-auto mt-5">O FoodJet conecta as diferentes partes da experiência de delivery em uma jornada integrada.</p></div><div className="relative mx-auto mt-12 max-w-5xl"><div className="hidden h-px bg-[#e5e7eb] lg:block"/><div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{nodes.map(({label,icon: Icon,text,active}, i) => <div key={label} className="relative rounded-3xl bg-[#fffaf7] p-5 text-center ring-1 ring-[#111827]/[.06] sm:p-7"><div className={`mx-auto grid size-14 place-items-center rounded-2xl ${active ? "bg-[#F97316] text-white shadow-[0_12px_25px_rgba(249,115,22,.25)]" : "bg-white text-[#F97316] shadow-sm"}`}><Icon className="size-6"/></div><h3 className="mt-5 text-[15px] font-extrabold text-[#111827]">{label}</h3><p className="mt-1 text-[12px] text-[#6b7280]">{text}</p>{i < nodes.length - 1 && <ChevronRight className="absolute -right-3 top-[calc(50%-10px)] z-10 hidden size-5 rounded-full bg-white text-[#F97316] shadow-sm lg:block"/>}</div>)}</div></div></div></section>
}
