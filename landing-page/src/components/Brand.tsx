import { PlaneTakeoff } from "lucide-react";

export function Brand({ light = false }: { light?: boolean }) {
  return (
    <a href="#inicio" aria-label="FoodJet, início" className="group inline-flex items-center gap-2">
      <span className="grid size-8 place-items-center rounded-[11px] bg-[#F97316] text-white shadow-[0_8px_20px_rgba(249,115,22,.28)] transition-transform duration-200 group-hover:-translate-y-0.5">
        <PlaneTakeoff className="size-[18px]" strokeWidth={2.8} />
      </span>
      <span className={`font-display text-[1.36rem] font-extrabold tracking-[-0.07em] ${light ? "text-white" : "text-[#111827]"}`}>
        Food<span className="text-[#F97316]">Jet</span>
      </span>
    </a>
  );
}
