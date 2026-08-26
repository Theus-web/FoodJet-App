// ==========================================================
// ASAAS WEBHOOK - FOODJET
// ==========================================================

const express = require("express");

const router = express.Router();

const WEBHOOK_TOKEN =
  process.env.ASAAS_WEBHOOK_TOKEN;

console.log(
  "========================================"
);

console.log(
  "🔔 FOODJET - ASAAS WEBHOOK"
);

console.log(
  "========================================"
);

console.log(
  "WEBHOOK TOKEN:",
  WEBHOOK_TOKEN
    ? "CONFIGURADO"
    : "NÃO CONFIGURADO"
);

if (WEBHOOK_TOKEN) {
  console.log(
    "TOKEN LENGTH:",
    WEBHOOK_TOKEN.length
  );
}

console.log(
  "📍 POST /api/asaas/webhook"
);

console.log(
  "========================================"
);

// ==========================================================
// WEBHOOK
// ==========================================================

router.post(
  "/asaas/webhook",
  async (req, res) => {

    try {

      console.log(
        "========================================"
      );

      console.log(
        "🔔 FOODJET - ASAAS WEBHOOK"
      );

      console.log(
        "========================================"
      );

      console.log(
        "📅 RECEBIDO:",
        new Date().toISOString()
      );

      console.log(
        "📌 EVENTO:",
        req.body?.event
      );

      console.log(
        "🆔 WEBHOOK ID:",
        req.body?.id
      );

      console.log(
        "💳 PAYMENT ID:",
        req.body?.payment?.id
      );

      console.log(
        "💰 VALOR:",
        req.body?.payment?.value
      );

      console.log(
        "📦 EXTERNAL REFERENCE:",
        req.body?.payment?.externalReference
      );

      // ======================================================
      // AUTENTICAÇÃO
      // ======================================================

      const recebido =
        req.headers[
          "asaas-access-token"
        ];

      if (!WEBHOOK_TOKEN) {

        console.error(
          "❌ ASAAS_WEBHOOK_TOKEN NÃO CONFIGURADO"
        );

        return res
          .status(500)
          .json({
            error:
              "Webhook token não configurado",
          });
      }

      if (!recebido) {

        console.error(
          "❌ ASAAS-ACCESS-TOKEN NÃO RECEBIDO"
        );

        return res
          .status(401)
          .json({
            error:
              "Unauthorized",
          });
      }

      if (recebido !== WEBHOOK_TOKEN) {

        console.error(
          "❌ TOKEN DO WEBHOOK INVÁLIDO"
        );

        return res
          .status(401)
          .json({
            error:
              "Unauthorized",
          });
      }

      console.log(
        "✅ ASSINATURA WEBHOOK ASAAS VALIDADA"
      );

      // ======================================================
      // EVENTO
      // ======================================================

      const event =
        req.body?.event;

      const payment =
        req.body?.payment;

      if (!payment) {

        console.log(
          "ℹ️ EVENTO SEM PAYMENT"
        );

        return res
          .status(200)
          .json({
            received: true,
          });
      }

      const paymentId =
        payment.id;

      const externalReference =
        payment.externalReference;

      console.log(
        "========================================"
      );

      console.log(
        "📌 EVENTO ASAAS:",
        event
      );

      console.log(
        "🆔 PAYMENT:",
        paymentId
      );

      console.log(
        "🔗 REFERÊNCIA:",
        externalReference
      );

      console.log(
        "========================================"
      );

      // ======================================================
      // PAYMENT_CREATED
      // ======================================================

      if (
        event ===
        "PAYMENT_CREATED"
      ) {

        console.log(
          "🟡 COBRANÇA ASAAS CRIADA"
        );

        return res
          .status(200)
          .json({
            received: true,
          });
      }

      // ======================================================
      // PAYMENT_RECEIVED
      // ======================================================

      if (
        event ===
        "PAYMENT_RECEIVED"
      ) {

        console.log(
          "========================================"
        );

        console.log(
          "💰 PAGAMENTO RECEBIDO"
        );

        console.log(
          "========================================"
        );

        console.log(
          "PAYMENT ID:",
          paymentId
        );

        console.log(
          "REFERENCE:",
          externalReference
        );

        console.log(
          "STATUS:",
          payment.status
        );

        // ----------------------------------------------------
        // AQUI VAMOS ATUALIZAR O PEDIDO FOODJET
        // ----------------------------------------------------

        /*
        Exemplo:

        const pedido =
          await Order.buscarPorReferencia(
            externalReference
          );

        if (pedido) {

          pedido.statusPagamento =
            "pago";

          pedido.status =
            "confirmado";

          pedido.paymentId =
            paymentId;

          await Order.atualizar(
            pedido.id,
            pedido
          );
        }
        */

        console.log(
          "✅ PAGAMENTO CONFIRMADO"
        );

        return res
          .status(200)
          .json({
            received: true,
          });
      }

      // ======================================================
      // PAYMENT_CONFIRMED
      // ======================================================

      if (
        event ===
        "PAYMENT_CONFIRMED"
      ) {

        console.log(
          "🟢 PAGAMENTO CONFIRMADO"
        );

        return res
          .status(200)
          .json({
            received: true,
          });
      }

      // ======================================================
      // PAYMENT_OVERDUE
      // ======================================================

      if (
        event ===
        "PAYMENT_OVERDUE"
      ) {

        console.log(
          "🟠 PAGAMENTO VENCIDO"
        );

        return res
          .status(200)
          .json({
            received: true,
          });
      }

      // ======================================================
      // PAYMENT_REFUNDED
      // ======================================================

      if (
        event ===
        "PAYMENT_REFUNDED"
      ) {

        console.log(
          "🔴 PAGAMENTO ESTORNADO"
        );

        return res
          .status(200)
          .json({
            received: true,
          });
      }

      // ======================================================
      // EVENTO NÃO UTILIZADO
      // ======================================================

      console.log(
        "ℹ️ EVENTO ASAAS NÃO TRATADO:",
        event
      );

      return res
        .status(200)
        .json({
          received: true,
        });

    } catch (error) {

      console.error(
        "========================================"
      );

      console.error(
        "❌ ERRO NO WEBHOOK ASAAS"
      );

      console.error(
        error.response?.data ||
        error.message
      );

      console.error(
        "========================================"
      );

      return res
        .status(500)
        .json({
          error:
            "Erro interno",
        });
    }
  }
);

module.exports = router;