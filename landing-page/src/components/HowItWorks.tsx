import { CheckCircle2, ClipboardList, MapPinned, UtensilsCrossed } from "lucide-react";

const steps = [
  { number: "01", title: "Escolha", text: "Encontre restaurantes e pratos que combinam com você.", icon: UtensilsCrossed },
  { number: "02", title: "Peça", text: "Monte seu pedido, escolha a forma de pagamento e confirme.", icon: ClipboardList },
  { number: "03", title: "Acompanhe", text: "Veja o andamento do pedido em tempo real.", icon: MapPinned },
  { number: "04", title: "Receba", text: "Seu pedido chega até você.", icon: CheckCircle2 },
];

export function HowItWorks() {
 return <section id="como-funciona" className="section-space bg-[#fffaf7]"><div className="container"><div className="max-w-2xl"><span className="eyebrow">COMO FUNCIONA</span><h2 className="section-title mt-4">Pedir pelo FoodJet<br/>é simples.</h2><p className="section-copy mt-5">Uma experiência direta, da descoberta do restaurante à chegada do seu pedido.</p></div><div className="mt-11 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{steps.map(({number,title,text,icon: Icon}) => <article key={number} className="group rounded-3xl bg-white p-6 shadow-[0_8px_25px_rgba(17,24,39,.04)] ring-1 ring-[#111827]/[.06] transition-all duration-200 hover:-translate-y-1 hover:shadow-[0_18px_32px_rgba(17,24,39,.1)]"><div className="flex items-start justify-between"><span className="font-display text-4xl font-extrabold tracking-[-.07em] text-[#e5e7eb] transition-colors group-hover:text-[#fed7aa]">{number}</span><span className="grid size-11 place-items-center rounded-2xl bg-[#fff0e7] text-[#F97316]"><Icon className="size-5"/></span></div><h3 className="mt-9 text-[17px] font-extrabold tracking-tight text-[#111827]">{title}</h3><p className="mt-2 text-sm leading-6 text-[#6b7280]">{text}</p></article>)}</div></div></section>
}
