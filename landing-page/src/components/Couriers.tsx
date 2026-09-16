import {
  ArrowRight,
  Bike,
  CheckCircle2,
  MapPin,
  Smartphone,
  Wallet,
} from "lucide-react";

const COURIER_IMAGE =
  "https://www.hyperlinkinfosystem.com/assets/case-study/cicd-pipeline-food-delivery-application/cicd-pipeline-food-delivery-application-hero.jpg";

export function Couriers() {
  return (
    <section
      id="entregadores"
      className="overflow-hidden bg-[#111827] py-20 text-white lg:py-28"
    >
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-6 sm:px-8 lg:grid-cols-[.94fr_1.06fr] lg:gap-16 lg:px-12">
        {/* IMAGEM */}
        <div className="relative order-2 lg:order-1">
          <div className="absolute -left-8 -top-8 h-32 w-32 rounded-full bg-orange-500/20 blur-2xl" />

          <div className="relative overflow-hidden rounded-[2rem] bg-gray-900 shadow-2xl ring-1 ring-white/10">
            <img
              src={COURIER_IMAGE}
              alt="Entregador utilizando uma motocicleta para realizar entregas"
              className="h-[520px] w-full object-cover object-center sm:h-[620px]"
              loading="lazy"
              referrerPolicy="no-referrer"
            />

            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-black/10" />

            <div className="absolute bottom-6 left-6 right-6 rounded-2xl border border-white/10 bg-black/50 p-4 backdrop-blur-md">
              <div className="flex items-center gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#F97316]">
                  <Bike className="h-5 w-5" />
                </div>

                <div>
                  <p className="text-xs text-white/60">
                    Entregador FoodJet
                  </p>

                  <p className="font-bold">
                    Mais pedidos. Mais oportunidades.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="absolute -right-5 -top-5 hidden rounded-2xl bg-white p-4 text-gray-900 shadow-xl sm:block">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100">
                <MapPin className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <p className="text-xs text-gray-500">
                  Rotas inteligentes
                </p>

                <p className="font-bold">
                  Mais praticidade
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* TEXTO */}
        <div className="order-1 lg:order-2">
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-orange-400/20 bg-orange-500/10 px-4 py-2 text-sm font-semibold text-orange-300">
            <Bike className="h-4 w-4" />
            Para entregadores
          </div>

          <h2 className="max-w-2xl text-4xl font-black leading-tight sm:text-5xl lg:text-6xl">
            Faça parte de quem
            <span className="text-[#F97316]"> faz o FoodJet acontecer.</span>
          </h2>

          <p className="mt-6 max-w-xl text-lg leading-8 text-white/70">
            Tenha uma plataforma pensada para facilitar sua rotina,
            organizar suas entregas e acompanhar seus ganhos.
          </p>

          <div className="mt-8 space-y-4">
            <div className="flex gap-4">
              <div className="mt-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-orange-500/10">
                <Smartphone className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <h3 className="font-bold">
                  Tudo pelo aplicativo
                </h3>

                <p className="mt-1 text-sm leading-6 text-white/60">
                  Receba informações dos pedidos e acompanhe suas
                  entregas em um só lugar.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="mt-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-orange-500/10">
                <Wallet className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <h3 className="font-bold">
                  Acompanhe seus ganhos
                </h3>

                <p className="mt-1 text-sm leading-6 text-white/60">
                  Tenha mais transparência sobre seus valores e
                  entregas realizadas.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="mt-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-orange-500/10">
                <MapPin className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <h3 className="font-bold">
                  Mais organização
                </h3>

                <p className="mt-1 text-sm leading-6 text-white/60">
                  Informações claras para você saber onde buscar e
                  entregar cada pedido.
                </p>
              </div>
            </div>
          </div>

          <div className="mt-8 grid gap-3 sm:grid-cols-2">
            <div className="flex items-center gap-2 text-sm text-white/70">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Aplicativo próprio
            </div>

            <div className="flex items-center gap-2 text-sm text-white/70">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Acompanhamento de pedidos
            </div>

            <div className="flex items-center gap-2 text-sm text-white/70">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Histórico de entregas
            </div>

            <div className="flex items-center gap-2 text-sm text-white/70">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Controle financeiro
            </div>
          </div>

          <a
            href="#apps"
            className="mt-9 inline-flex items-center gap-2 rounded-xl bg-[#F97316] px-6 py-3.5 font-bold text-white transition hover:bg-orange-600"
          >
            Quero ser entregador
            <ArrowRight className="h-5 w-5" />
          </a>
        </div>
      </div>
    </section>
  );
}