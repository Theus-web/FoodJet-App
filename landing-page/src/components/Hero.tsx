import {
  ArrowRight,
  CheckCircle2,
  Clock3,
  MapPin,
  Smartphone,
  Star,
} from "lucide-react";

const HERO_IMAGE =
  "https://www.hyperlinkinfosystem.com/assets/case-study/cicd-pipeline-food-delivery-application/cicd-pipeline-food-delivery-application-hero.jpg";

export function Hero() {
  return (
    <section
      id="inicio"
      className="relative overflow-hidden bg-white"
    >
      <div className="absolute inset-0 -z-10">
        <div className="absolute left-[-180px] top-[-180px] h-[420px] w-[420px] rounded-full bg-orange-100/60 blur-3xl" />
        <div className="absolute bottom-[-220px] right-[-160px] h-[480px] w-[480px] rounded-full bg-orange-50 blur-3xl" />
      </div>

      <div className="mx-auto grid max-w-7xl items-center gap-12 px-6 pb-16 pt-10 sm:px-8 lg:min-h-[780px] lg:grid-cols-2 lg:gap-16 lg:px-12 lg:pb-28 lg:pt-20">
        {/* TEXTO */}
        <div className="relative z-10">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-orange-200 bg-orange-50 px-4 py-2 text-sm font-semibold text-orange-700">
            <span className="flex h-2 w-2 rounded-full bg-orange-500" />
            O delivery que conecta sua cidade
          </div>

          <h1 className="max-w-3xl text-5xl font-black leading-[1.02] tracking-tight text-[#111827] sm:text-6xl lg:text-7xl">
            Seu pedido.
            <br />
            <span className="text-[#F97316]">Seu jeito.</span>
            <br />
            Seu FoodJet.
          </h1>

          <p className="mt-6 max-w-xl text-lg leading-8 text-gray-600 sm:text-xl">
            Uma nova experiência de delivery que conecta clientes,
            restaurantes e entregadores de forma simples, rápida e
            inteligente.
          </p>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <a
              href="#apps"
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-[#F97316] px-6 py-3.5 font-bold text-white shadow-lg shadow-orange-200 transition hover:-translate-y-0.5 hover:bg-orange-600"
            >
              Conheça o FoodJet
              <ArrowRight className="h-5 w-5" />
            </a>

            <a
              href="#como-funciona"
              className="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-6 py-3.5 font-bold text-gray-800 transition hover:border-orange-300 hover:text-[#F97316]"
            >
              Como funciona
            </a>
          </div>

          <div className="mt-8 grid max-w-xl grid-cols-2 gap-4 sm:grid-cols-4">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <CheckCircle2 className="h-5 w-5 text-[#F97316]" />
              Rápido
            </div>

            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Clock3 className="h-5 w-5 text-[#F97316]" />
              Prático
            </div>

            <div className="flex items-center gap-2 text-sm text-gray-600">
              <MapPin className="h-5 w-5 text-[#F97316]" />
              Local
            </div>

            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Smartphone className="h-5 w-5 text-[#F97316]" />
              Digital
            </div>
          </div>

          <div className="mt-10 flex items-center gap-4">
            <div className="flex -space-x-2">
              <div className="flex h-9 w-9 items-center justify-center rounded-full border-2 border-white bg-orange-200 text-xs font-bold text-orange-700">
                F
              </div>

              <div className="flex h-9 w-9 items-center justify-center rounded-full border-2 border-white bg-orange-300 text-xs font-bold text-orange-800">
                J
              </div>

              <div className="flex h-9 w-9 items-center justify-center rounded-full border-2 border-white bg-orange-400 text-xs font-bold text-white">
                +
              </div>
            </div>

            <div>
              <div className="flex items-center gap-1">
                <Star className="h-4 w-4 fill-orange-400 text-orange-400" />
                <Star className="h-4 w-4 fill-orange-400 text-orange-400" />
                <Star className="h-4 w-4 fill-orange-400 text-orange-400" />
                <Star className="h-4 w-4 fill-orange-400 text-orange-400" />
                <Star className="h-4 w-4 fill-orange-400 text-orange-400" />
              </div>

              <p className="text-xs text-gray-500">
                Uma experiência feita para a sua cidade
              </p>
            </div>
          </div>
        </div>

        {/* IMAGEM */}
        <div className="relative">
          <div className="absolute -right-6 -top-6 z-20 hidden rounded-2xl border border-white/80 bg-white/95 p-4 shadow-xl sm:block">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100">
                <Clock3 className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <p className="text-xs font-medium text-gray-500">
                  Entrega rápida
                </p>
                <p className="font-bold text-gray-900">
                  Acompanhe em tempo real
                </p>
              </div>
            </div>
          </div>

          <div className="relative mx-auto aspect-[4/5] max-w-[560px] overflow-hidden rounded-[2rem] bg-gray-100 shadow-2xl shadow-orange-100 ring-1 ring-black/5 sm:aspect-[5/6] lg:aspect-[4/5]">
            <img
              src={HERO_IMAGE}
              alt="Entregador realizando uma entrega de comida"
              className="h-full w-full object-cover object-center"
              loading="eager"
              referrerPolicy="no-referrer"
            />

            <div className="absolute inset-0 bg-gradient-to-t from-black/45 via-transparent to-transparent" />

            <div className="absolute bottom-5 left-5 right-5 rounded-2xl border border-white/20 bg-white/95 p-4 shadow-xl backdrop-blur">
              <div className="flex items-center gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#F97316] text-white">
                  <MapPin className="h-5 w-5" />
                </div>

                <div className="min-w-0">
                  <p className="text-xs font-medium text-gray-500">
                    Seu pedido está a caminho
                  </p>

                  <p className="truncate font-bold text-gray-900">
                    Acompanhe cada etapa pelo FoodJet
                  </p>
                </div>

                <div className="ml-auto hidden rounded-full bg-green-50 px-3 py-1 text-xs font-bold text-green-600 sm:block">
                  ONLINE
                </div>
              </div>
            </div>
          </div>

          <div className="absolute -bottom-5 -left-5 z-20 hidden rounded-2xl bg-white p-4 shadow-xl sm:block">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-orange-100">
                <Smartphone className="h-5 w-5 text-[#F97316]" />
              </div>

              <div>
                <p className="text-xs text-gray-500">
                  Tudo pelo app
                </p>
                <p className="font-bold text-gray-900">
                  Simples e seguro
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}