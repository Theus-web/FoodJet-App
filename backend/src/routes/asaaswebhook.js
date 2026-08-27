const express = require("express");

const router = express.Router();

const db = require("../database/db");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const WEBHOOK_TOKEN =
  process.env.ASAAS_WEBHOOK_TOKEN || "";

// ============================================================
// LOG INICIAL
// ============================================================

console.log("========================================");
console.log("🔔 FOODJET - ASAAS WEBHOOK");
console.log("========================================");

console.log(
  "WEBHOOK TOKEN:",
  WEBHOOK_TOKEN ? "CONFIGURADO" : "NÃO CONFIGURADO"
);

console.log(
  "TOKEN LENGTH:",
  WEBHOOK_TOKEN.length
);

console.log(
  "📍 POST /api/asaas/webhook"
);

console.log("========================================");

// ============================================================
// FUNÇÃO AUXILIAR
// ============================================================

function obterToken(req) {
  return (
    req.headers["asaas-access-token"] ||
    req.headers["x-asaas-access-token"] ||
    req.headers["authorization"] ||
    ""
  );
}

// ============================================================
// NORMALIZAR TOKEN
// ============================================================

function normalizarToken(token) {
  if (!token) {
    return "";
  }

  let valor = String(token).trim();

  if (
    valor.toLowerCase().startsWith("bearer ")
  ) {
    valor = valor.substring(7).trim();
  }

  return valor;
}

// ============================================================
// LOCALIZAR PEDIDO
// ============================================================

function localizarPedido(pedidos, referencia, paymentId) {

  if (!Array.isArray(pedidos)) {
    return {
      pedido: null,
      indice: -1,
    };
  }

  const referenciaString =
    referencia !== undefined &&
    referencia !== null
      ? String(referencia).trim()
      : "";

  const paymentIdString =
    paymentId !== undefined &&
    paymentId !== null
      ? String(paymentId).trim()
      : "";

  // ==========================================================
  // PRIMEIRA TENTATIVA:
  // externalReference
  // ==========================================================

  if (referenciaString) {

    const indice =
      pedidos.findIndex((pedido) => {

        if (!pedido) {
          return false;
        }

        const referencias = [

          pedido.externalReference,

          pedido.referencia,

          pedido.pedidoId,

          pedido.id,

        ]
          .filter(
            (valor) =>
              valor !== undefined &&
              valor !== null
          )
          .map((valor) =>
            String(valor).trim()
          );

        return referencias.includes(
          referenciaString
        );
      });

    if (indice !== -1) {

      return {
        pedido: pedidos[indice],
        indice,
      };

    }
  }

  // ==========================================================
  // SEGUNDA TENTATIVA:
  // ID DA COBRANÇA ASAAS
  // ==========================================================

  if (paymentIdString) {

    const indice =
      pedidos.findIndex((pedido) => {

        if (!pedido) {
          return false;
        }

        const ids = [

          pedido.asaasPaymentId,

          pedido.pagamentoId,

          pedido.paymentId,

        ]
          .filter(
            (valor) =>
              valor !== undefined &&
              valor !== null
          )
          .map((valor) =>
            String(valor).trim()
          );

        return ids.includes(
          paymentIdString
        );
      });

    if (indice !== -1) {

      return {
        pedido: pedidos[indice],
        indice,
      };

    }
  }

  return {
    pedido: null,
    indice: -1,
  };
}

// ============================================================
// IDENTIFICAR STATUS DE PAGAMENTO
// ============================================================

function pagamentoFoiAprovado(status) {

  const statusNormalizado =
    String(status || "")
      .trim()
      .toUpperCase();

  return [
    "RECEIVED",
    "CONFIRMED",
    "RECEIVED_IN_CASH",
  ].includes(
    statusNormalizado
  );
}

// ============================================================
// IDENTIFICAR STATUS PENDENTE
// ============================================================

function pagamentoEstáPendente(status) {

  const statusNormalizado =
    String(status || "")
      .trim()
      .toUpperCase();

  return [
    "PENDING",
    "AWAITING_RISK_ANALYSIS",
    "AWAITING_CHARGEBACK_REVERSAL",
  ].includes(
    statusNormalizado
  );
}

// ============================================================
// IDENTIFICAR PAGAMENTO NEGADO/CANCELADO
// ============================================================

function pagamentoFoiCancelado(status) {

  const statusNormalizado =
    String(status || "")
      .trim()
      .toUpperCase();

  return [
    "OVERDUE",
    "REFUNDED",
    "REFUND_REQUESTED",
    "CHARGEBACK_REQUESTED",
    "CHARGEBACK_DISPUTE",
    "AWAITING_CHARGEBACK_REVERSAL",
    "DUNNING_REQUESTED",
    "DUNNING_RECEIVED",
    "CANCELED",
  ].includes(
    statusNormalizado
  );
}

// ============================================================
// WEBHOOK
// ============================================================

router.post(
  "/webhook",
  async (req, res) => {

    console.log("========================================");
    console.log("🔔 ASAAS WEBHOOK RECEBIDO");
    console.log("========================================");

    try {

      // ======================================================
      // VALIDAR TOKEN
      // ======================================================

      const tokenRecebido =
        normalizarToken(
          obterToken(req)
        );

      if (!WEBHOOK_TOKEN) {

        console.error(
          "❌ ASAAS_WEBHOOK_TOKEN NÃO CONFIGURADO"
        );

        return res.status(500).json({
          sucesso: false,
          erro:
            "Webhook Asaas não configurado.",
        });
      }

      if (
        !tokenRecebido ||
        tokenRecebido !== WEBHOOK_TOKEN
      ) {

        console.error(
          "❌ TOKEN DO WEBHOOK ASAAS INVÁLIDO"
        );

        return res.status(401).json({
          sucesso: false,
          erro:
            "Token do webhook inválido.",
        });
      }

      console.log(
        "✅ TOKEN DO WEBHOOK VALIDADO"
      );

      // ======================================================
      // PAYLOAD
      // ======================================================

      const evento =
        req.body || {};

      console.log(
        "📌 EVENTO:",
        evento.event
      );

      console.log(
        "📦 PAYMENT ID:",
        evento?.payment?.id || ""
      );

      console.log(
        "📊 STATUS:",
        evento?.payment?.status || ""
      );

      console.log(
        "🔖 REFERÊNCIA:",
        evento?.payment?.externalReference || ""
      );

      // ======================================================
      // VALIDAR EVENTO
      // ======================================================

      if (!evento || !evento.event) {

        console.warn(
          "⚠️ Webhook recebido sem evento."
        );

        return res.status(200).json({
          sucesso: true,
          processado: false,
          mensagem:
            "Evento não informado.",
        });
      }

      // ======================================================
      // PAYMENT
      // ======================================================

      const payment =
        evento.payment || {};

      const paymentId =
        payment.id
          ? String(payment.id).trim()
          : "";

      const externalReference =
        payment.externalReference
          ? String(
              payment.externalReference
            ).trim()
          : "";

      const status =
        payment.status
          ? String(payment.status).trim()
          : "";

      // ======================================================
      // EVENTOS DE PAGAMENTO
      // ======================================================

      const eventosPagamento = [

        "PAYMENT_CREATED",

        "PAYMENT_UPDATED",

        "PAYMENT_CONFIRMED",

        "PAYMENT_RECEIVED",

        "PAYMENT_OVERDUE",

        "PAYMENT_DELETED",

        "PAYMENT_REFUNDED",

        "PAYMENT_REFUND_IN_PROGRESS",

        "PAYMENT_REFUND_CANCELLED",

        "PAYMENT_CHARGEBACK_REQUESTED",

        "PAYMENT_CHARGEBACK_DISPUTE",

        "PAYMENT_AWAITING_CHARGEBACK_REVERSAL",

      ];

      if (
        !eventosPagamento.includes(
          evento.event
        )
      ) {

        console.log(
          "ℹ️ Evento não relacionado diretamente a pagamento:",
          evento.event
        );

        return res.status(200).json({
          sucesso: true,
          processado: false,
          evento:
            evento.event,
          mensagem:
            "Evento recebido e ignorado.",
        });
      }

      // ======================================================
      // VALIDAR PAYMENT ID
      // ======================================================

      if (!paymentId) {

        console.warn(
          "⚠️ Webhook sem payment.id."
        );

        return res.status(200).json({
          sucesso: true,
          processado: false,
          mensagem:
            "Payment ID não informado.",
        });
      }

      // ======================================================
      // LER BANCO
      // ======================================================

      await db.read();

      if (!db.data) {
        db.data = {};
      }

      if (
        !Array.isArray(
          db.data.pedidos
        )
      ) {

        db.data.pedidos = [];

      }

      // ======================================================
      // LOCALIZAR PEDIDO
      // ======================================================

      const resultado =
        localizarPedido(
          db.data.pedidos,
          externalReference,
          paymentId
        );

      const pedido =
        resultado.pedido;

      const indice =
        resultado.indice;

      // ======================================================
      // PEDIDO NÃO ENCONTRADO
      // ======================================================

      if (
        !pedido ||
        indice === -1
      ) {

        console.warn(
          "⚠️ PEDIDO FOODJET NÃO ENCONTRADO"
        );

        console.warn(
          "🔖 externalReference:",
          externalReference
        );

        console.warn(
          "🆔 paymentId:",
          paymentId
        );

        /*
         * Retornamos 200.
         *
         * Isso evita que o Asaas fique reenviando
         * indefinidamente o mesmo evento enquanto
         * o pedido ainda não estiver disponível.
         */

        return res.status(200).json({

          sucesso: true,

          processado: false,

          paymentId,

          externalReference,

          mensagem:
            "Pedido FoodJet ainda não encontrado.",

        });
      }

      // ======================================================
      // DADOS ANTERIORES
      // ======================================================

      const statusAnterior =
        pedido.pagamentoStatus ||
        pedido.statusPagamento ||
        "";

      const pedidoStatusAnterior =
        pedido.status ||
        "";

      console.log("========================================");
      console.log(
        "📦 PEDIDO FOODJET ENCONTRADO"
      );
      console.log("========================================");

      console.log(
        "🆔 PEDIDO:",
        pedido.id
      );

      console.log(
        "🔖 REFERÊNCIA:",
        externalReference
      );

      console.log(
        "💳 PAYMENT ID:",
        paymentId
      );

      console.log(
        "📊 STATUS ANTERIOR:",
        statusAnterior
      );

      console.log(
        "📦 STATUS PEDIDO:",
        pedidoStatusAnterior
      );

      console.log(
        "📊 NOVO STATUS PAGAMENTO:",
        status
      );

      // ======================================================
      // ATUALIZAR DADOS ASAAS
      // ======================================================

      pedido.asaasPaymentId =
        paymentId;

      pedido.paymentId =
        paymentId;

      pedido.pagamentoId =
        paymentId;

      pedido.externalReference =
        externalReference ||
        pedido.externalReference ||
        String(pedido.id);

      pedido.pagamentoStatus =
        status;

      pedido.statusPagamento =
        status;

      pedido.pagamentoEvento =
        evento.event;

      pedido.pagamentoAtualizadoEm =
        new Date().toISOString();

      // ======================================================
      // PAGAMENTO APROVADO
      // ======================================================

      if (
        pagamentoFoiAprovado(
          status
        )
      ) {

        pedido.pagamentoAprovado =
          true;

        pedido.pagamentoConfirmado =
          true;

        pedido.pagamentoConfirmadoEm =
          pedido.pagamentoConfirmadoEm ||
          new Date().toISOString();

        pedido.statusPagamento =
          status;

        /*
         * O pedido só passa para
         * AGUARDANDO_RESTAURANTE quando
         * o pagamento realmente foi recebido.
         */

        pedido.status =
          "AGUARDANDO_RESTAURANTE";

        console.log(
          "========================================"
        );

        console.log(
          "💰 PIX APROVADO"
        );

        console.log(
          "========================================"
        );

        console.log(
          "📦 PEDIDO:",
          pedido.id
        );

        console.log(
          "💳 STATUS:",
          status
        );

        console.log(
          "🏪 NOVO STATUS:",
          pedido.status
        );

      }

      // ======================================================
      // PAGAMENTO PENDENTE
      // ======================================================

      else if (
        pagamentoEstáPendente(
          status
        )
      ) {

        pedido.pagamentoAprovado =
          false;

        pedido.pagamentoConfirmado =
          false;

        /*
         * Não alteramos o status operacional
         * do pedido caso ele já esteja em outro
         * estado controlado pelo restaurante.
         */

        console.log(
          "⏳ PAGAMENTO PIX PENDENTE"
        );

      }

      // ======================================================
      // PAGAMENTO CANCELADO / ESTORNADO
      // ======================================================

      else if (
        pagamentoFoiCancelado(
          status
        )
      ) {

        pedido.pagamentoAprovado =
          false;

        pedido.pagamentoConfirmado =
          false;

        pedido.pagamentoCancelado =
          true;

        pedido.pagamentoCanceladoEm =
          new Date().toISOString();

        console.log(
          "⚠️ PAGAMENTO PIX CANCELADO/ESTORNADO"
        );

      }

      // ======================================================
      // SALVAR BANCO
      // ======================================================

      db.data.pedidos[indice] =
        pedido;

      await db.write();

      console.log(
        "========================================"
      );

      console.log(
        "💾 PEDIDO ATUALIZADO NO FOODJET"
      );

      console.log(
        "========================================"
      );

      console.log(
        "📦 PEDIDO:",
        pedido.id
      );

      console.log(
        "💳 PAYMENT ID:",
        paymentId
      );

      console.log(
        "📊 PAGAMENTO:",
        pedido.pagamentoStatus
      );

      console.log(
        "💰 APROVADO:",
        pedido.pagamentoAprovado
      );

      console.log(
        "📦 STATUS PEDIDO:",
        pedido.status
      );

      // ======================================================
      // SOCKET.IO
      // ======================================================

      try {

        if (
          global.io &&
          pedido.id
        ) {

          const salaPedido =
            `pedido_${pedido.id}`;

          global.io
            .to(salaPedido)
            .emit(
              "pagamento_atualizado",
              {

                pedidoId:
                  pedido.id,

                pagamentoId:
                  paymentId,

                paymentId:
                  paymentId,

                statusPagamento:
                  pedido.pagamentoStatus,

                pagamentoAprovado:
                  pedido.pagamentoAprovado,

                pagamentoConfirmado:
                  pedido.pagamentoConfirmado,

                status:
                  pedido.status,

                externalReference:
                  pedido.externalReference,

              }
            );

          console.log(
            "📡 SOCKET ENVIADO PARA:",
            salaPedido
          );

          // ==================================================
          // RESTAURANTE
          // ==================================================

          const restauranteId =
            pedido.restauranteId ||
            pedido.restaurantId;

          if (
            restauranteId
          ) {

            const salaRestaurante =
              `restaurante_${restauranteId}`;

            global.io
              .to(
                salaRestaurante
              )
              .emit(
                "pagamento_confirmado",
                {

                  pedidoId:
                    pedido.id,

                  pagamentoId:
                    paymentId,

                  paymentId:
                    paymentId,

                  statusPagamento:
                    pedido.pagamentoStatus,

                  pagamentoAprovado:
                    pedido.pagamentoAprovado,

                  status:
                    pedido.status,

                }
              );

            console.log(
              "🏪 SOCKET ENVIADO PARA:",
              salaRestaurante
            );

          }

        }

      } catch (socketErro) {

        /*
         * Falha no Socket.IO não pode fazer
         * o webhook falhar depois que o banco
         * já foi atualizado.
         */

        console.error(
          "⚠️ ERRO SOCKET.IO:"
        );

        console.error(
          socketErro?.message
        );

      }

      // ======================================================
      // RESPOSTA ASAAS
      // ======================================================

      return res.status(200).json({

        sucesso: true,

        processado: true,

        evento:
          evento.event,

        pedidoId:
          pedido.id,

        pagamentoId:
          paymentId,

        externalReference:
          externalReference,

        statusPagamento:
          pedido.pagamentoStatus,

        pagamentoAprovado:
          pedido.pagamentoAprovado,

        statusPedido:
          pedido.status,

      });

    } catch (erro) {

      console.error(
        "========================================"
      );

      console.error(
        "❌ ERRO PROCESSANDO WEBHOOK ASAAS"
      );

      console.error(
        "========================================"
      );

      console.error(
        "ERRO:",
        erro?.message
      );

      console.error(
        "STACK:",
        erro?.stack
      );

      /*
       * 500 informa ao Asaas que o evento não
       * foi processado corretamente.
       */

      return res.status(500).json({

        sucesso: false,

        erro:
          "Erro ao processar webhook Asaas.",

      });

    }

  }
);

// ============================================================
// EXPORTAR
// ============================================================

module.exports = router;