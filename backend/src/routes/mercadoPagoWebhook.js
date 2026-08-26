
/**
 * ============================================================
 * FOODJET - MERCADO PAGO WEBHOOK
 * ============================================================
 *
 * PRODUÇÃO
 *
 * - Recebe Webhooks do Mercado Pago
 * - Valida assinatura HMAC
 * - Consulta Order
 * - Identifica pagamento
 * - Atualiza pedido FoodJet
 * - Notifica restaurante via Socket.IO
 *
 * ============================================================
 */

require("dotenv").config();

const express = require("express");
const crypto = require("crypto");

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

console.log(
  "SECRET INICIO:",
  WEBHOOK_SECRET.substring(0, 8)
);

console.log(
  "SECRET FINAL:",
  WEBHOOK_SECRET.slice(-8)
);

console.log("========================================");

// ============================================================
// EXTRAIR X-SIGNATURE
// ============================================================

function extrairAssinatura(xSignature) {
  const resultado = {
    ts: null,
    v1: null,
  };

  if (!xSignature) {
    return resultado;
  }

  const partes = String(xSignature).split(",");

  for (const parte of partes) {
    const indice = parte.indexOf("=");

    if (indice === -1) {
      continue;
    }

    const chave = parte
      .substring(0, indice)
      .trim()
      .toLowerCase();

    const valor = parte
      .substring(indice + 1)
      .trim();

    if (chave === "ts") {
      resultado.ts = valor;
    }

    if (chave === "v1") {
      resultado.v1 = valor;
    }
  }

  return resultado;
}

// ============================================================
// COMPARAÇÃO SEGURA
// ============================================================

function compararHashes(hashCalculado, hashRecebido) {
  if (!hashCalculado || !hashRecebido) {
    return false;
  }

  const calculado = String(hashCalculado)
    .trim()
    .toLowerCase();

  const recebido = String(hashRecebido)
    .trim()
    .toLowerCase();

  if (
    !/^[a-f0-9]{64}$/.test(calculado) ||
    !/^[a-f0-9]{64}$/.test(recebido)
  ) {
    return false;
  }

  const bufferCalculado =
    Buffer.from(calculado, "hex");

  const bufferRecebido =
    Buffer.from(recebido, "hex");

  if (
    bufferCalculado.length !==
    bufferRecebido.length
  ) {
    return false;
  }

  return crypto.timingSafeEqual(
    bufferCalculado,
    bufferRecebido
  );
}

// ============================================================
// VALIDAÇÃO MANUAL HMAC
// ============================================================
//
// Mercado Pago:
//
// HMAC-SHA256(
//   secret,
//   "id:<data.id>;request-id:<x-request-id>;ts:<ts>;"
// )
//
// O data.id usado na assinatura vem da QUERY.
// ============================================================

function validarAssinaturaManual(req) {
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
  console.log("🔐 VALIDAÇÃO MANUAL HMAC");
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
      "❌ X-SIGNATURE AUSENTE"
    );

    return false;
  }

  if (!xRequestId) {
    console.error(
      "❌ X-REQUEST-ID AUSENTE"
    );

    return false;
  }

  if (!dataId) {
    console.error(
      "❌ DATA.ID AUSENTE"
    );

    return false;
  }

  const {
    ts,
    v1,
  } = extrairAssinatura(
    xSignature
  );

  console.log(
    "TIMESTAMP:",
    ts || "NÃO ENCONTRADO"
  );

  console.log(
    "V1:",
    v1 ? "RECEBIDO" : "NÃO RECEBIDO"
  );

  if (!ts || !v1) {
    console.error(
      "❌ TS OU V1 AUSENTE"
    );

    return false;
  }

  // ==========================================================
  // MANIFEST
  // ==========================================================

  const manifest =
    `id:${String(dataId)};` +
    `request-id:${String(xRequestId)};` +
    `ts:${String(ts)};`;

  console.log(
    "MANIFEST:",
    manifest
  );

  // ==========================================================
  // HMAC SHA256
  // ==========================================================

  const hashCalculado =
    crypto
      .createHmac(
        "sha256",
        WEBHOOK_SECRET
      )
      .update(
        manifest,
        "utf8"
      )
      .digest("hex");

  console.log(
    "HASH CALCULADO:",
    hashCalculado
  );

  console.log(
    "HASH RECEBIDO:",
    v1
  );

  // ==========================================================
  // COMPARAÇÃO
  // ==========================================================

  const valido =
    compararHashes(
      hashCalculado,
      v1
    );

  if (!valido) {
    console.error(
      "❌ ASSINATURA HMAC INVÁLIDA"
    );

    return false;
  }

  console.log("========================================");
  console.log(
    "✅ ASSINATURA HMAC VALIDADA"
  );
  console.log(
    "✅ WEBHOOK AUTÊNTICO"
  );
  console.log("========================================");

  return true;
}

// ============================================================
// VALIDAÇÃO SDK
// ============================================================

function validarAssinatura(req) {
  if (!WEBHOOK_SECRET) {
    console.error(
      "❌ WEBHOOK SECRET NÃO CONFIGURADO"
    );

    return false;
  }

  const xSignature =
    req.headers["x-signature"];

  const xRequestId =
    req.headers["x-request-id"];

  const dataId =
    req.query?.["data.id"];

  if (
    !xSignature ||
    !xRequestId ||
    !dataId
  ) {
    console.error(
      "❌ DADOS NECESSÁRIOS PARA ASSINATURA AUSENTES"
    );

    return false;
  }

  // ==========================================================
  // SDK OFICIAL
  // ==========================================================

  try {
    WebhookSignatureValidator.validate({
      xSignature: String(xSignature),
      xRequestId: String(xRequestId),
      dataId: String(dataId),
      secret: WEBHOOK_SECRET,
    });

    console.log("========================================");
    console.log(
      "✅ ASSINATURA VALIDADA PELO SDK"
    );
    console.log(
      "✅ MERCADO PAGO WEBHOOK AUTÊNTICO"
    );
    console.log("========================================");

    return true;

  } catch (erro) {

    console.warn(
      "⚠️ SDK REJEITOU A ASSINATURA."
    );

    console.warn(
      "ERRO SDK:",
      erro?.message || erro
    );

    console.warn(
      "⚠️ TENTANDO HMAC MANUAL."
    );
  }

  // ==========================================================
  // HMAC MANUAL
  // ==========================================================

  return validarAssinaturaManual(req);
}

// ============================================================
// LOCALIZAR PEDIDO
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

  let pedido =
    pedidos.find(
      (item) =>
        String(item.id) ===
        String(referencia)
    );

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

  pedidos[index] = pedido;

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

  global.io
    .to(sala)
    .emit(
      "pagamento_aprovado",
      pedido
    );

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

    // ========================================================
    // TIPO
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
    // DATA ID
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

    // ========================================================
    // CONSULTAR ORDER
    // ========================================================

    console.log("========================================");
    console.log(
      "🔎 CONSULTANDO ORDER"
    );

    console.log(
      "🆔 ORDER ID:",
      dataId
    );

    console.log("========================================");

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
      order?.transactions?.payments?.[0] ||
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
      payment?.id || "NÃO INFORMADO"
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
      // ======================================================
      // IDEMPOTÊNCIA
      // ======================================================

      if (
        pedido.pagamentoStatus === "APROVADO" &&
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

      // ======================================================
      // ATUALIZAR PAGAMENTO
      // ======================================================

      pedido.pagamentoStatus =
        "APROVADO";

      pedido.pagamentoStatusDetalhe =
        paymentDetail;

      pedido.pagamentoMetodo =
        "PIX";

      pedido.mercadoPagoOrderId =
        order.id;

      pedido.mercadoPagoPaymentId =
        payment?.id || null;

      pedido.mercadoPagoOrderStatus =
        order.status;

      pedido.mercadoPagoOrderStatusDetail =
        order.status_detail;

      pedido.pagamentoConfirmadoEm =
        new Date().toISOString();

      pedido.pagamentoAprovado =
        true;

      // ======================================================
      // STATUS FOODJET
      // ======================================================

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

      // ======================================================
      // SALVAR
      // ======================================================

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

      // ======================================================
      // SOCKET
      // ======================================================

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
      order.status === "cancelled" ||
      order.status === "expired"
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

