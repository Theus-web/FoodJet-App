/**
 * ============================================================
 * FOODJET - MERCADO PAGO WEBHOOK
 * ============================================================
 *
 * PRODUÇÃO
 *
 * - Recebe Webhooks do Mercado Pago
 * - Valida assinatura pelo SDK oficial
 * - Consulta Order
 * - Identifica pagamento
 * - Atualiza pedido FoodJet
 * - Notifica restaurante via Socket.IO
 *
 * ============================================================
 */

require("dotenv").config();

const express = require("express");

const {
  WebhookSignatureValidator,
} = require("mercadopago");

const Order = require("../models/order");

const {
  consultarOrder,
} = require("../services/mercadoPagoService");

const router = express.Router();

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const WEBHOOK_SECRET = String(
  process.env.MERCADOPAGO_WEBHOOK_SECRET || ""
).trim();

console.log("========================================");
console.log("🔔 FOODJET - MERCADO PAGO WEBHOOK");
console.log("========================================");

console.log(
  "WEBHOOK SECRET:",
  WEBHOOK_SECRET ? "CONFIGURADO" : "NÃO CONFIGURADO"
);

console.log(
  "SECRET LENGTH:",
  WEBHOOK_SECRET.length
);

console.log("========================================");

// ============================================================
// VALIDAÇÃO OFICIAL DO MERCADO PAGO
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
    req.query?.["data.id"];

  console.log("========================================");
  console.log("🔐 VALIDAÇÃO OFICIAL MERCADO PAGO");
  console.log("========================================");

  console.log(
    "X-SIGNATURE:",
    xSignature ? "RECEBIDO" : "NÃO RECEBIDO"
  );

  console.log(
    "X-REQUEST-ID:",
    xRequestId ? "RECEBIDO" : "NÃO RECEBIDO"
  );

  console.log(
    "DATA.ID QUERY:",
    dataId || "NÃO RECEBIDO"
  );

  if (!xSignature) {
    console.error(
      "❌ HEADER X-SIGNATURE AUSENTE"
    );

    return false;
  }

  if (!xRequestId) {
    console.error(
      "❌ HEADER X-REQUEST-ID AUSENTE"
    );

    return false;
  }

  if (!dataId) {
    console.error(
      "❌ QUERY PARAM data.id AUSENTE"
    );

    return false;
  }

  try {
    WebhookSignatureValidator.validate({
      xSignature: String(xSignature),
      xRequestId: String(xRequestId),
      dataId: String(dataId),
      secret: WEBHOOK_SECRET,
    });

    console.log(
      "========================================"
    );

    console.log(
      "✅ ASSINATURA VALIDADA PELO SDK"
    );

    console.log(
      "✅ MERCADO PAGO WEBHOOK AUTÊNTICO"
    );

    console.log(
      "========================================"
    );

    return true;

  } catch (erro) {

    console.error(
      "========================================"
    );

    console.error(
      "❌ ASSINATURA REJEITADA PELO SDK"
    );

    console.error(
      "ERRO:",
      erro?.message || erro
    );

    console.error(
      "========================================"
    );

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
  // TENTA PELO ID DIRETO
  // ----------------------------------------------------------

  let pedido =
    pedidos.find(
      (item) =>
        String(item.id) ===
        String(referencia)
    );

  // ----------------------------------------------------------
  // TENTA FOODJET-123
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

  console.log(
    "========================================"
  );

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

  console.log(
    "========================================"
  );
}

// ============================================================
// WEBHOOK PRINCIPAL
// ============================================================

async function webhook(req, res) {

  console.log(
    "========================================"
  );

  console.log(
    "🔔 FOODJET - MERCADO PAGO WEBHOOK"
  );

  console.log(
    "========================================"
  );

  console.log(
    "📅 RECEBIDO:",
    new Date().toISOString()
  );

  const type =
    req.body?.type;

  const action =
    req.body?.action;

  const liveMode =
    req.body?.live_mode;

  const dataId =
    req.query?.["data.id"];

  console.log(
    "📌 TYPE:",
    type || "NÃO INFORMADO"
  );

  console.log(
    "📌 ACTION:",
    action || "NÃO INFORMADO"
  );

  console.log(
    "🆔 DATA ID:",
    dataId || "NÃO INFORMADO"
  );

  console.log(
    "🌎 LIVE MODE:",
    liveMode
  );

  console.log(
    "🆔 APPLICATION ID:",
    req.body?.application_id ||
      "NÃO INFORMADO"
  );

  console.log(
    "👤 USER ID:",
    req.body?.user_id ||
      "NÃO INFORMADO"
  );

  console.log(
    "📦 BODY DATA.ID:",
    req.body?.data?.id ||
      "NÃO INFORMADO"
  );

  console.log(
    "🔗 QUERY:",
    JSON.stringify(
      req.query
    )
  );

  console.log(
    "📦 BODY TYPE:",
    req.body?.type ||
      "NÃO INFORMADO"
  );

  console.log(
    "📦 BODY ACTION:",
    req.body?.action ||
      "NÃO INFORMADO"
  );

  console.log(
    "========================================"
  );

  // ==========================================================
  // VALIDAR ASSINATURA
  // ==========================================================

  const assinaturaValida =
    validarAssinatura(req);

  if (!assinaturaValida) {

    console.error(
      "========================================"
    );

    console.error(
      "❌ WEBHOOK REJEITADO POR ASSINATURA"
    );

    console.error(
      "========================================"
    );

    return res
      .status(401)
      .json({
        sucesso: false,
        erro:
          "Assinatura do webhook inválida.",
      });
  }

  // ==========================================================
  // ASSINATURA CONFIRMADA
  // ==========================================================

  console.log(
    "========================================"
  );

  console.log(
    "🔐 ASSINATURA CONFIRMADA"
  );

  console.log(
    "========================================"
  );

  console.log(
    "🆔 APPLICATION ID:",
    req.body?.application_id ||
      "NÃO INFORMADO"
  );

  console.log(
    "👤 USER ID:",
    req.body?.user_id ||
      "NÃO INFORMADO"
  );

  console.log(
    "🆔 ORDER ID:",
    req.body?.data?.id ||
      dataId ||
      "NÃO INFORMADO"
  );

  console.log(
    "========================================"
  );

  // ==========================================================
  // EVENTOS QUE NÃO SÃO ORDER
  // ==========================================================

  if (type !== "order") {

    console.log(
      "ℹ️ EVENTO IGNORADO:",
      type
    );

    return res
      .status(200)
      .json({
        recebido: true,
        ignorado: true,
        tipo: type,
      });
  }

  // ==========================================================
  // VALIDAR DATA.ID
  // ==========================================================

  if (!dataId) {

    console.error(
      "❌ ORDER SEM DATA.ID"
    );

    return res
      .status(400)
      .json({
        sucesso: false,
        erro:
          "data.id não informado.",
      });
  }

  // ==========================================================
  // CONSULTAR ORDER
  // ==========================================================

  try {

    console.log(
      "========================================"
    );

    console.log(
      "🔎 CONSULTANDO ORDER"
    );

    console.log(
      "🆔 ORDER ID:",
      dataId
    );

    console.log(
      "========================================"
    );

    const order =
      await consultarOrder(
        dataId
      );

    if (!order) {

      throw new Error(
        "Mercado Pago não retornou a Order."
      );
    }

    console.log(
      "========================================"
    );

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

    console.log(
      "========================================"
    );

    // ========================================================
    // PAYMENT
    // ========================================================

    const payment =
      order?.transactions?.payments?.[0] ||
      null;

    const paymentStatus =
      payment?.status ||
      null;

    const paymentDetail =
      payment?.status_detail ||
      null;

    console.log(
      "----------------------------------------"
    );

    console.log(
      "💳 PAYMENT"
    );

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

    console.log(
      "----------------------------------------"
    );

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
      order.status === "processed" &&
      paymentStatus === "processed" &&
      paymentDetail === "accredited";

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
      // ATUALIZAR PAGAMENTO
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

      console.log(
        "========================================"
      );

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

      console.log(
        "========================================"
      );

      // ------------------------------------------------------
      // SOCKET
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

    console.error(
      "========================================"
    );

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

    console.error(
      "========================================"
    );

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
// LOG
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