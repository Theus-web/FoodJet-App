import {
  ArrowRight,
  BarChart3,
  CheckCircle2,
  ClipboardList,
  Clock3,
  Smartphone,
  Store,
} from "lucide-react";

const RESTAURANT_IMAGE =
  "https://sr-website-01.shiprocket.in/sr-website/quick-restaurant-iWE6FG.webp";

export function Restaurants() {
  return (
    <section
      id="restaurantes"
      className="overflow-hidden bg-white py-20 lg:py-28"
    >
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-6 sm:px-8 lg:grid-cols-[1.06fr_.94fr] lg:gap-16 lg:px-12">
        {/* TEXTO */}
        <div>
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-orange-200 bg-orange-50 px-4 py-2 text-sm font-semibold text-orange-700">
            <Store className="h-4 w-4" />
            Para restaurantes
          </div>

          <h2 className="max-w-2xl text-4xl font-black leading-tight tracking-tight text-[#111827] sm:text-5xl lg:text-6xl">
            Seu restaurante
            <span className="text-[#F97316]"> merece voar.</span>
          </h2>

          <p className="mt-6 max-w-xl text-lg leading-8 text-gray-600">
            O FoodJet ajuda restaurantes a receber mais pedidos,
            organizar a operação e acompanhar o desempenho do negócio
            em um único lugar.
          </p>

          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            <div className="rounded-2xl border border-gray-100 bg-gray-50 p-5">
              <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-orange-100">
                <ClipboardList className="h-5 w-5 text-[#F97316]" />
              </div>

              <h3 className="font-bold text-gray-900">
                Pedidos organizados
              </h3>

              <p className="mt-2 text-sm leading-6 text-gray-500">
                Receba e acompanhe seus pedidos com mais clareza.
              </p>
            </div>

            <div className="rounded-2xl border border-gray-100 bg-gray-50 p-5">
              <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-orange-100">
                <BarChart3 className="h-5 w-5 text-[#F97316]" />
              </div>

              <h3 className="font-bold text-gray-900">
                Visão do negócio
              </h3>

              <p className="mt-2 text-sm leading-6 text-gray-500">
                Acompanhe vendas e informações importantes da operação.
              </p>
            </div>

            <div className="rounded-2xl border border-gray-100 bg-gray-50 p-5">
              <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-orange-100">
                <Smartphone className="h-5 w-5 text-[#F97316]" />
              </div>

              <h3 className="font-bold text-gray-900">
                Gestão pelo app
              </h3>

              <p className="mt-2 text-sm leading-6 text-gray-500">
                Controle sua operação diretamente pelo aplicativo.
              </p>
            </div>

            <div className="rounded-2xl border border-gray-100 bg-gray-50 p-5">
              <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-orange-100">
                <Clock3 className="h-5 w-5 text-[#F97316]" />
              </div>

              <h3 className="font-bold text-gray-900">
                Mais agilidade
              </h3>

              <p className="mt-2 text-sm leading-6 text-gray-500">
                Simplifique o atendimento e o fluxo dos pedidos.
              </p>
            </div>
          </div>

          <div className="mt-8 space-y-3">
            <div className="flex items-center gap-3 text-sm font-medium text-gray-700">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Cardápio digital
            </div>

            <div className="flex items-center gap-3 text-sm font-medium text-gray-700">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Gestão de pedidos
            </div>

            <div className="flex items-center gap-3 text-sm font-medium text-gray-700">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Acompanhamento financeiro
            </div>
          </div>

          <a
            href="#apps"
            className="mt-9 inline-flex items-center gap-2 rounded-xl bg-[#F97316] px-6 py-3.5 font-bold text-white shadow-lg shadow-orange-100 transition hover:-translate-y-0.5 hover:bg-orange-600"
          >
            Quero ser parceiro
            <ArrowRight className="h-5 w-5" />
          </a>
        </div>

        {/* IMAGEM */}
        <div className="relative">
          <div className="absolute -bottom-10 -right-10 h-48 w-48 rounded-full bg-orange-100 blur-3xl" />

          <div className="relative overflow-hidden rounded-[2rem] bg-gray-100 shadow-2xl ring-1 ring-black/5">
            <img
              src={RESTAURANT_IMAGE}
              alt="Restaurante realizando uma entrega de pedido"
              className="h-[520px] w-full object-cover object-center opacity-95 sm:h-[620px]"
              loading="lazy"
              referrerPolicy="no-referrer"
            />

            <div className="absolute inset-0 bg-gradient-to-t from-black/65 via-transparent to-black/5" />

            <div className="absolute bottom-6 left-6 right-6 rounded-2xl border border-white/20 bg-white/95 p-5 shadow-xl backdrop-blur">
              <div className="flex items-center gap-4">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#F97316] text-white">
                  <Store className="h-6 w-6" />
                </div>

                <div className="min-w-0">
                  <p className="text-xs font-medium text-gray-500">
                    FoodJet Parceiro
                  </p>

                  <p className="text-lg font-black text-gray-900">
                    Seu restaurante conectado ao delivery
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="absolute -left-5 -top-5 hidden rounded-2xl bg-white p-4 shadow-xl sm:block">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100">
                <BarChart3 className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <p className="text-xs text-gray-500">
                  Gestão simples
                </p>

                <p className="font-bold text-gray-900">
                  Tudo em um só lugar
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}