/**
 * ============================================================
 * FOODJET - MERCADO PAGO WEBHOOK
 * ============================================================
 *
 * PRODUÇÃO
 *
 * Responsável por:
 *
 * - Receber Webhooks do Mercado Pago
 * - Validar assinatura oficial
 * - Consultar Order
 * - Identificar pagamento
 * - Atualizar pedido FoodJet
 * - Notificar restaurante via Socket.IO
 *
 * ============================================================
 */

require("dotenv").config({
  override: true,
});

const express = require("express");

const {
  WebhookSignatureValidator,
} = require("mercadopago");

const Order = require("../models/order");

const {
  consultarOrder,
} = require("../services/mercadoPagoService");

// ============================================================
// ROUTER
// ============================================================

const router = express.Router();

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const WEBHOOK_SECRET = String(
  process.env.MERCADOPAGO_WEBHOOK_SECRET || ""
).trim();

// ============================================================
// LOG INICIAL
// ============================================================

console.log("========================================");
console.log("🔔 FOODJET - MERCADO PAGO WEBHOOK");
console.log("========================================");

console.log(
  "WEBHOOK SECRET:",
  WEBHOOK_SECRET
    ? "CONFIGURADO"
    : "NÃO CONFIGURADO"
);

console.log("========================================");

// ============================================================
// VALIDAR ASSINATURA
// ============================================================

function validarAssinatura(req) {
  if (!WEBHOOK_SECRET) {
    console.error(
      "❌ MERCADOPAGO_WEBHOOK_SECRET NÃO CONFIGURADO"
    );

    return false;
  }

  const xSignature =
    req.headers["x-signature"];

  const xRequestId =
    req.headers["x-request-id"];

  const dataId =
    req.query?.["data.id"] ||
    req.body?.data?.id;

  console.log("========================================");
  console.log("🔐 VALIDANDO ASSINATURA WEBHOOK");
  console.log("========================================");

  console.log(
    "X-SIGNATURE:",
    xSignature
      ? "RECEBIDO"
      : "NÃO RECEBIDO"
  );

  console.log(
    "X-REQUEST-ID:",
    xRequestId
      ? "RECEBIDO"
      : "NÃO RECEBIDO"
  );

  console.log(
    "DATA.ID:",
    dataId || "NÃO RECEBIDO"
  );

  // ----------------------------------------------------------
  // VALIDAÇÃO BÁSICA
  // ----------------------------------------------------------

  if (!xSignature) {
    console.error(
      "❌ X-SIGNATURE NÃO RECEBIDO"
    );

    return false;
  }

  if (!xRequestId) {
    console.error(
      "❌ X-REQUEST-ID NÃO RECEBIDO"
    );

    return false;
  }

  if (!dataId) {
    console.error(
      "❌ DATA.ID NÃO RECEBIDO"
    );

    return false;
  }

  // ----------------------------------------------------------
  // EXTRAIR TS E V1
  // ----------------------------------------------------------

  let timestamp = null;
  let assinatura = null;

  const partes =
    String(xSignature).split(",");

  for (const parte of partes) {
    const indice =
      parte.indexOf("=");

    if (indice === -1) {
      continue;
    }

    const chave =
      parte
        .substring(0, indice)
        .trim();

    const valor =
      parte
        .substring(indice + 1)
        .trim();

    if (chave === "ts") {
      timestamp = valor;
    }

    if (chave === "v1") {
      assinatura = valor;
    }
  }

  console.log(
    "TIMESTAMP:",
    timestamp || "NÃO ENCONTRADO"
  );

  console.log(
    "HASH RECEBIDO:",
    assinatura
      ? "SIM"
      : "NÃO"
  );

  if (!timestamp || !assinatura) {
    console.error(
      "❌ TS OU V1 NÃO ENCONTRADO"
    );

    return false;
  }

  // ----------------------------------------------------------
  // VALIDAÇÃO OFICIAL SDK
  // ----------------------------------------------------------

  try {
    WebhookSignatureValidator.validate({
      xSignature: String(xSignature),
      xRequestId: String(xRequestId),
      dataId: String(dataId),
      secret: WEBHOOK_SECRET,
    });

    console.log("========================================");
    console.log(
      "✅ ASSINATURA WEBHOOK VALIDADA"
    );
    console.log(
      "✅ SDK OFICIAL MERCADO PAGO"
    );
    console.log("========================================");

    return true;

  } catch (erro) {
    console.error("========================================");
    console.error(
      "❌ ASSINATURA WEBHOOK INVÁLIDA"
    );

    console.error(
      "❌ O SDK DO MERCADO PAGO REJEITOU A ASSINATURA."
    );

    console.error(
      "⚠️ VERIFIQUE O MERCADOPAGO_WEBHOOK_SECRET."
    );

    console.error(
      "⚠️ O SECRET PRECISA SER DA MESMA APLICAÇÃO."
    );

    console.error(
      "⚠️ USE O SECRET DA APLICAÇÃO DE PRODUÇÃO."
    );

    console.error(
      "ERRO:",
      erro?.message || erro
    );

    console.error("========================================");

    return false;
  }
}

// ============================================================
// LOCALIZAR PEDIDO FOODJET
// ============================================================

async function localizarPedido(order) {
  const referencia =
    order?.external_reference;

  if (!referencia) {
    return null;
  }

  const pedidos =
    await Order.listar();

  if (!Array.isArray(pedidos)) {
    return null;
  }

  // ----------------------------------------------------------
  // REFERÊNCIA EXATA
  // ----------------------------------------------------------

  let pedido =
    pedidos.find(
      (item) =>
        String(item.id) ===
        String(referencia)
    );

  // ----------------------------------------------------------
  // FOODJET-123
  // ----------------------------------------------------------

  if (!pedido) {
    const referenciaString =
      String(referencia);

    const match =
      referenciaString.match(
        /^FOODJET-(\d+)$/
      );

    if (match) {
      pedido =
        pedidos.find(
          (item) =>
            String(item.id) ===
            String(match[1])
        );
    }
  }

  return pedido || null;
}

// ============================================================
// SALVAR PEDIDO
// ============================================================

async function salvarPedidoAtualizado(
  pedido
) {
  const pedidos =
    await Order.listar();

  const index =
    pedidos.findIndex(
      (item) =>
        String(item.id) ===
        String(pedido.id)
    );

  if (index === -1) {
    throw new Error(
      `Pedido FoodJet ${pedido.id} não encontrado.`
    );
  }

  pedidos[index] =
    pedido;

  const {
    db,
  } = require("../config/database");

  await db.write();

  return pedidos[index];
}

// ============================================================
// NOTIFICAR RESTAURANTE
// ============================================================

function notificarRestaurante(
  pedido
) {
  if (!global.io) {
    console.log(
      "⚠️ Socket.IO ainda não disponível."
    );

    return;
  }

  if (!pedido?.restauranteId) {
    console.log(
      "⚠️ Pedido sem restauranteId."
    );

    return;
  }

  const sala =
    `restaurante_${pedido.restauranteId}`;

  // ----------------------------------------------------------
  // PAGAMENTO APROVADO
  // ----------------------------------------------------------

  global.io
    .to(sala)
    .emit(
      "pagamento_aprovado",
      pedido
    );

  // ----------------------------------------------------------
  // NOVO PEDIDO
  // ----------------------------------------------------------

  global.io
    .to(sala)
    .emit(
      "novo_pedido",
      pedido
    );

  console.log("========================================");
  console.log(
    "📡 PEDIDO ENVIADO AO RESTAURANTE"
  );

  console.log(
    "🏪 SALA:",
    sala
  );

  console.log(
    "🆔 PEDIDO:",
    pedido.id
  );

  console.log(
    "💰 TOTAL:",
    pedido.total
  );

  console.log("========================================");
}

// ============================================================
// WEBHOOK PRINCIPAL
// ============================================================

async function webhook(req, res) {
  console.log("========================================");
  console.log(
    "🔔 FOODJET - MERCADO PAGO WEBHOOK"
  );
  console.log("========================================");

  console.log(
    "📅 RECEBIDO:",
    new Date().toISOString()
  );

  const tipo =
    req.body?.type ||
    req.query?.type ||
    null;

  const action =
    req.body?.action ||
    null;

  const dataId =
    req.query?.["data.id"] ||
    req.body?.data?.id ||
    null;

  const externalReference =
    req.query?.["data.external_reference"] ||
    null;

  console.log(
    "📌 TYPE:",
    tipo
  );

  console.log(
    "📌 ACTION:",
    action
  );

  console.log(
    "🆔 DATA ID:",
    dataId
  );

  console.log(
    "🔗 EXTERNAL REFERENCE:",
    externalReference
  );

  console.log(
    "🌎 LIVE MODE:",
    req.body?.live_mode
  );

  console.log(
    "🔗 QUERY:",
    JSON.stringify(req.query)
  );

  try {

    // ========================================================
    // VALIDAR ASSINATURA
    // ========================================================

    const assinaturaValida =
      validarAssinatura(req);

    if (!assinaturaValida) {

      console.error(
        "❌ WEBHOOK REJEITADO POR ASSINATURA"
      );

      return res
        .status(401)
        .json({
          sucesso: false,
          erro:
            "Assinatura do webhook inválida.",
        });
    }

    // ========================================================
    // TIPO DO EVENTO
    // ========================================================

    if (tipo !== "order") {

      console.log(
        "ℹ️ EVENTO IGNORADO:",
        tipo
      );

      return res
        .status(200)
        .json({
          recebido: true,
          ignorado: true,
        });
    }

    // ========================================================
    // ORDER ID
    // ========================================================

    if (!dataId) {

      console.error(
        "❌ ORDER ID NÃO INFORMADO"
      );

      return res
        .status(400)
        .json({
          sucesso: false,
          erro:
            "Order ID não informado.",
        });
    }

    console.log("========================================");
    console.log(
      "🔎 CONSULTANDO ORDER"
    );

    console.log(
      "🆔 ORDER ID:",
      dataId
    );

    console.log("========================================");

    // ========================================================
    // CONSULTAR ORDER
    // ========================================================

    const order =
      await consultarOrder(
        dataId
      );

    if (!order) {
      throw new Error(
        "Mercado Pago não retornou a Order."
      );
    }

    console.log("========================================");
    console.log(
      "✅ ORDER CONSULTADA"
    );

    console.log(
      "🆔 ORDER ID:",
      order.id
    );

    console.log(
      "📊 STATUS:",
      order.status
    );

    console.log(
      "📋 STATUS DETAIL:",
      order.status_detail
    );

    console.log(
      "🔗 EXTERNAL REFERENCE:",
      order.external_reference
    );

    console.log("========================================");

    // ========================================================
    // PAYMENT
    // ========================================================

    const payment =
      order
        ?.transactions
        ?.payments
        ?.[0] ||
      null;

    const paymentStatus =
      payment?.status ||
      null;

    const paymentDetail =
      payment?.status_detail ||
      null;

    console.log("----------------------------------------");
    console.log("💳 PAYMENT");

    console.log(
      "🆔 PAYMENT ID:",
      payment?.id ||
      "NÃO INFORMADO"
    );

    console.log(
      "📊 PAYMENT STATUS:",
      paymentStatus
    );

    console.log(
      "📋 PAYMENT DETAIL:",
      paymentDetail
    );

    console.log(
      "💰 PAYMENT AMOUNT:",
      payment?.amount
    );

    console.log("----------------------------------------");

    // ========================================================
    // LOCALIZAR PEDIDO
    // ========================================================

    const pedido =
      await localizarPedido(
        order
      );

    if (!pedido) {

      console.error(
        "⚠️ PEDIDO FOODJET NÃO ENCONTRADO"
      );

      console.error(
        "EXTERNAL REFERENCE:",
        order.external_reference
      );

      // Evento é legítimo.
      // Não retornar 401.

      return res
        .status(200)
        .json({
          recebido: true,
          pedidoEncontrado: false,
        });
    }

    console.log(
      "✅ PEDIDO FOODJET ENCONTRADO"
    );

    console.log(
      "🆔 PEDIDO:",
      pedido.id
    );

    console.log(
      "🏪 RESTAURANTE:",
      pedido.restauranteId
    );

    console.log(
      "📌 STATUS ATUAL:",
      pedido.status
    );

    // ========================================================
    // PAGAMENTO APROVADO
    // ========================================================

    const aprovado =
      order.status ===
        "processed" &&
      paymentStatus ===
        "processed" &&
      paymentDetail ===
        "accredited";

    if (aprovado) {

      // ------------------------------------------------------
      // IDEMPOTÊNCIA
      // ------------------------------------------------------

      if (
        pedido.pagamentoStatus ===
          "APROVADO" &&
        String(
          pedido.mercadoPagoOrderId
        ) ===
          String(order.id)
      ) {

        console.log(
          "ℹ️ PAGAMENTO JÁ PROCESSADO"
        );

        return res
          .status(200)
          .json({
            recebido: true,
            jaProcessado: true,
          });
      }

      // ------------------------------------------------------
      // PAGAMENTO
      // ------------------------------------------------------

      pedido.pagamentoStatus =
        "APROVADO";

      pedido.pagamentoStatusDetalhe =
        paymentDetail;

      pedido.pagamentoMetodo =
        "PIX";

      pedido.mercadoPagoOrderId =
        order.id;

      pedido.mercadoPagoPaymentId =
        payment?.id ||
        null;

      pedido.mercadoPagoOrderStatus =
        order.status;

      pedido.mercadoPagoOrderStatusDetail =
        order.status_detail;

      pedido.pagamentoConfirmadoEm =
        new Date().toISOString();

      pedido.pagamentoAprovado =
        true;

      // ------------------------------------------------------
      // STATUS FOODJET
      // ------------------------------------------------------

      if (
        pedido.status ===
          "AGUARDANDO_PAGAMENTO" ||
        pedido.status ===
          "PAGAMENTO_PENDENTE" ||
        !pedido.status
      ) {

        pedido.status =
          "AGUARDANDO_RESTAURANTE";
      }

      pedido.atualizadoEm =
        new Date().toISOString();

      // ------------------------------------------------------
      // SALVAR
      // ------------------------------------------------------

      await salvarPedidoAtualizado(
        pedido
      );

      console.log("========================================");
      console.log(
        "💰 PAGAMENTO PIX APROVADO"
      );

      console.log(
        "🆔 PEDIDO:",
        pedido.id
      );

      console.log(
        "🆔 MP ORDER:",
        order.id
      );

      console.log(
        "🆔 MP PAYMENT:",
        payment?.id
      );

      console.log(
        "📌 NOVO STATUS:",
        pedido.status
      );

      console.log("========================================");

      // ------------------------------------------------------
      // SOCKET.IO
      // ------------------------------------------------------

      notificarRestaurante(
        pedido
      );

      return res
        .status(200)
        .json({
          recebido: true,
          pagamentoAprovado: true,
          pedidoAtualizado: true,
          pedidoId:
            pedido.id,
        });
    }

    // ========================================================
    // PIX PENDENTE
    // ========================================================

    if (
      order.status ===
        "action_required"
    ) {

      pedido.pagamentoStatus =
        "PENDENTE";

      pedido.pagamentoStatusDetalhe =
        paymentDetail ||
        order.status_detail ||
        null;

      pedido.pagamentoAprovado =
        false;

      pedido.mercadoPagoOrderId =
        order.id;

      pedido.mercadoPagoPaymentId =
        payment?.id ||
        pedido.mercadoPagoPaymentId ||
        null;

      pedido.mercadoPagoOrderStatus =
        order.status;

      pedido.mercadoPagoOrderStatusDetail =
        order.status_detail;

      pedido.atualizadoEm =
        new Date().toISOString();

      await salvarPedidoAtualizado(
        pedido
      );

      console.log(
        "⏳ PIX AINDA PENDENTE"
      );

      return res
        .status(200)
        .json({
          recebido: true,
          pagamentoAprovado: false,
          pagamentoPendente: true,
          orderId:
            order.id,
        });
    }

    // ========================================================
    // FALHOU
    // ========================================================

    if (
      order.status ===
        "failed"
    ) {

      pedido.pagamentoStatus =
        "FALHOU";

      pedido.pagamentoStatusDetalhe =
        paymentDetail ||
        order.status_detail ||
        null;

      pedido.pagamentoAprovado =
        false;

      pedido.mercadoPagoOrderId =
        order.id;

      pedido.mercadoPagoPaymentId =
        payment?.id ||
        pedido.mercadoPagoPaymentId ||
        null;

      pedido.mercadoPagoOrderStatus =
        order.status;

      pedido.mercadoPagoOrderStatusDetail =
        order.status_detail;

      pedido.atualizadoEm =
        new Date().toISOString();

      await salvarPedidoAtualizado(
        pedido
      );

      console.log(
        "❌ PAGAMENTO FALHOU"
      );
    }

    // ========================================================
    // CANCELADO / EXPIRADO
    // ========================================================

    if (
      order.status ===
        "cancelled" ||
      order.status ===
        "expired"
    ) {

      pedido.pagamentoStatus =
        "CANCELADO";

      pedido.pagamentoStatusDetalhe =
        paymentDetail ||
        order.status_detail ||
        null;

      pedido.pagamentoAprovado =
        false;

      pedido.mercadoPagoOrderId =
        order.id;

      pedido.mercadoPagoPaymentId =
        payment?.id ||
        pedido.mercadoPagoPaymentId ||
        null;

      pedido.mercadoPagoOrderStatus =
        order.status;

      pedido.mercadoPagoOrderStatusDetail =
        order.status_detail;

      pedido.atualizadoEm =
        new Date().toISOString();

      await salvarPedidoAtualizado(
        pedido
      );

      console.log(
        "❌ PAGAMENTO CANCELADO/EXPIRADO"
      );
    }

    // ========================================================
    // RESPOSTA FINAL
    // ========================================================

    return res
      .status(200)
      .json({
        recebido: true,
        pagamentoAprovado: false,
        status:
          order.status,
        statusDetail:
          order.status_detail,
      });

  } catch (erro) {

    console.error("========================================");
    console.error(
      "❌ ERRO NO WEBHOOK MERCADO PAGO"
    );

    console.error(
      "MENSAGEM:",
      erro?.message
    );

    console.error(
      "STACK:",
      erro?.stack
    );

    console.error("========================================");

    return res
      .status(500)
      .json({
        sucesso: false,
        erro:
          "Erro ao processar webhook.",
      });
  }
}

// ============================================================
// ROTA POST
// ============================================================

router.post(
  "/webhook",
  webhook
);

// ============================================================
// LOG DA ROTA
// ============================================================

console.log(
  "🔔 WEBHOOK MERCADO PAGO CARREGADO"
);

console.log(
  "📍 POST /api/mercadopago/webhook"
);

// ============================================================
// EXPORTAÇÃO
// ============================================================

module.exports = router;