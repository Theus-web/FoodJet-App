import { Menu, X } from "lucide-react";
import { useState } from "react";
import { Brand } from "./Brand";

const navItems = [
  ["Início", "#inicio"], ["Como funciona", "#como-funciona"], ["Para restaurantes", "#restaurantes"], ["Para entregadores", "#entregadores"], ["Sobre o FoodJet", "#ecossistema"], ["FAQ", "#faq"],
];

export function Header() {
  const [open, setOpen] = useState(false);
  const close = () => setOpen(false);
  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-[#111827]/[.06] bg-white/[.9] backdrop-blur-xl">
      <div className="container flex h-[72px] items-center justify-between gap-4">
        <Brand />
        <nav className="hidden items-center gap-5 xl:flex" aria-label="Navegação principal">
          {navItems.map(([name, target]) => <a key={name} href={target} className="text-[13px] font-semibold text-[#4b5563] transition-colors hover:text-[#F97316]">{name}</a>)}
        </nav>
        <div className="hidden items-center gap-2 xl:flex">
          <a href="#apps" className="rounded-xl px-4 py-2.5 text-[13px] font-bold text-[#374151] transition-colors hover:bg-[#f3f4f6]">Entrar</a>
          <a href="#apps" className="rounded-xl bg-[#F97316] px-4 py-2.5 text-[13px] font-extrabold text-white shadow-[0_8px_20px_rgba(249,115,22,.22)] transition-all hover:-translate-y-0.5 hover:bg-[#ea650f] active:scale-[.97]">Pedir agora</a>
        </div>
        <div className="flex items-center gap-2 xl:hidden"><a href="#apps" className="rounded-xl bg-[#F97316] px-3 py-2 text-xs font-extrabold text-white">Pedir</a><button onClick={() => setOpen(!open)} aria-label={open ? "Fechar menu" : "Abrir menu"} aria-expanded={open} className="grid size-10 place-items-center rounded-xl bg-[#f3f4f6] text-[#111827]">{open ? <X className="size-5"/> : <Menu className="size-5"/>}</button></div>
      </div>
      {open && <div className="border-t border-[#111827]/[.06] bg-white px-4 pb-5 pt-3 shadow-xl xl:hidden"><nav className="mx-auto flex max-w-xl flex-col" aria-label="Menu mobile">{navItems.map(([name, target]) => <a key={name} onClick={close} href={target} className="rounded-xl px-4 py-3 text-sm font-bold text-[#374151] hover:bg-[#fff5ef] hover:text-[#F97316]">{name}</a>)}<a onClick={close} href="#apps" className="mt-2 rounded-xl bg-[#111827] px-4 py-3 text-center text-sm font-bold text-white">Entrar na plataforma</a></nav></div>}
    </header>
  );
}
