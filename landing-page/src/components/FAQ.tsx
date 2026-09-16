import { ChevronDown } from "lucide-react";

const faqs = [
 ["O que é o FoodJet?", "O FoodJet é uma plataforma que conecta clientes, restaurantes e entregadores em uma experiência de delivery."],
 ["Como faço um pedido?", "Você escolhe um restaurante, seleciona os produtos, informa o endereço, escolhe a forma de pagamento e acompanha o pedido."],
 ["Como meu restaurante pode entrar no FoodJet?", "O restaurante pode solicitar cadastro como parceiro através da plataforma."],
 ["Como faço para ser entregador?", "É possível realizar o cadastro como entregador através da plataforma FoodJet."],
 ["Onde o FoodJet está disponível?", "A disponibilidade é informada conforme as regiões atendidas pela plataforma."],
 ["Quais formas de pagamento são aceitas?", "As formas disponíveis são apresentadas de acordo com as opções atualmente habilitadas na plataforma."],
];

export function FAQ() {
 return <section id="faq" className="section-space bg-[#fffaf7]"><div className="container grid gap-10 lg:grid-cols-[.76fr_1.24fr] lg:gap-20"><div><span className="eyebrow">FAQ</span><h2 className="section-title mt-4">Dúvidas? A gente ajuda.</h2><p className="section-copy mt-5">Encontre respostas rápidas sobre a plataforma FoodJet.</p></div><div className="divide-y divide-[#111827]/[.08] rounded-3xl bg-white px-5 shadow-[0_10px_32px_rgba(17,24,39,.04)] ring-1 ring-[#111827]/[.06] sm:px-7">{faqs.map(([question,answer],i) => <details key={question} open={i === 0} className="group py-5"><summary className="flex list-none items-center justify-between gap-5 text-[14px] font-extrabold text-[#111827] marker:content-none"><span>{question}</span><ChevronDown className="size-4 shrink-0 text-[#F97316] transition-transform duration-200 group-open:rotate-180"/></summary><p className="max-w-2xl pr-8 pt-3 text-sm leading-6 text-[#6b7280]">{answer}</p></details>)}</div></div></section>
}
