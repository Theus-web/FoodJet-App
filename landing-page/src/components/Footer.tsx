import { MapPin } from "lucide-react";
import { Brand } from "./Brand";

const groups = [
 ["FoodJet", [["Sobre nós", "#ecossistema"],["Como funciona", "#como-funciona"],["Contato", "#faq"],["FAQ", "#faq"]]],
 ["Para clientes", [["Pedir agora", "#apps"],["Aplicativo", "#apps"],["Meus pedidos", "#apps"]]],
 ["Para restaurantes", [["Seja parceiro", "#restaurantes"],["FoodJet Parceiro", "#apps"]]],
 ["Para entregadores", [["Seja entregador", "#entregadores"],["FoodJet Entregador", "#apps"]]],
 ["Suporte", [["Central de ajuda", "#faq"],["Fale conosco", "#faq"],["Termos de uso", "#faq"],["Política de privacidade", "#faq"]]],
];

export function Footer() {
 return <footer className="bg-[#111827] pb-7 pt-12 text-white sm:pt-16"><div className="container"><div className="grid gap-10 lg:grid-cols-[1.4fr_repeat(5,1fr)] lg:gap-6"><div><Brand light/><p className="mt-5 max-w-[230px] text-[13px] leading-6 text-white/55">Uma experiência de delivery simples, rápida e do seu jeito.</p></div>{groups.map(([title,links]) => <div key={title as string}><h3 className="text-[12px] font-extrabold text-white">{title as string}</h3><ul className="mt-4 space-y-2.5">{(links as string[][]).map(([name,target]) => <li key={name}><a href={target} className="text-[12px] font-medium text-white/55 transition-colors hover:text-[#ff9a52]">{name}</a></li>)}</ul></div>)}</div><div className="mt-12 flex flex-col gap-3 border-t border-white/[.1] pt-6 text-[11px] font-medium text-white/45 sm:flex-row sm:items-center sm:justify-between"><p>© 2026 FoodJet. Todos os direitos reservados.</p><p className="flex items-center gap-1.5"><MapPin className="size-3.5 text-[#ff9a52]"/> Ipatinga — Minas Gerais — Brasil</p></div></div></footer>
}
