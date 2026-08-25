/**
 * ============================================================
 * FOODJET - MERCADO PAGO WEBHOOK
 * ============================================================
 *
 * PRODUÇÃO
 *
 * Fluxo:
 *
 * Mercado Pago
 *      ↓
 * POST /api/mercadopago/webhook
 *      ↓
 * valida x-signature
 *      ↓
 * consulta Order no Mercado Pago
 *      ↓
 * verifica status do pagamento
 *      ↓
 * atualiza pedido FoodJet
 *      ↓
 * Socket.IO
 *      ↓
 * restaurante recebe pedido
 *
 * ============================================================
 */

require("dotenv").config({ override: true });

const crypto = require("crypto");

const Order = require("../models/order");

const {
  consultarOrder,
} = require("../services/mercadoPagoService");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const WEBHOOK_SECRET =
  process.env.MERCADOPAGO_WEBHOOK_SECRET?.trim();

// ============================================================
// LOG
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
// VALIDAR ASSINATURA MERCADO PAGO
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

  console.log(
    "========================================"
  );

  console.log(
    "🔐 VALIDANDO ASSINATURA WEBHOOK"
  );

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
    "DATA.ID QUERY:",
    dataId || "NÃO RECEBIDO"
  );

  // ==========================================================
  // VALIDAÇÃO BÁSICA
  // ==========================================================

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

  // ==========================================================
  // EXTRAIR TS E V1
  // ==========================================================

  let ts = null;
  let v1 = null;

  const partes =
    String(xSignature).split(",");

  for (const parte of partes) {
    const separador =
      parte.indexOf("=");

    if (separador === -1) {
      continue;
    }

    const chave =
      parte
        .substring(0, separador)
        .trim();

    const valor =
      parte
        .substring(separador + 1)
        .trim();

    if (chave === "ts") {
      ts = valor;
    }

    if (chave === "v1") {
      v1 = valor;
    }
  }

  console.log(
    "TIMESTAMP:",
    ts || "NÃO ENCONTRADO"
  );

  console.log(
    "HASH RECEBIDO:",
    v1
      ? "SIM"
      : "NÃO"
  );

  if (!ts || !v1) {
    console.error(
      "❌ TS OU V1 NÃO ENCONTRADO"
    );

    return false;
  }

  // ==========================================================
  // MANIFEST
  // ==========================================================
  //
  // Mercado Pago:
  //
  // id:[data.id];
  // request-id:[x-request-id];
  // ts:[ts];
  //
  // ==========================================================

  const manifest =
    `id:${dataId};` +
    `request-id:${xRequestId};` +
    `ts:${ts};`;

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

  // ==========================================================
  // COMPARAÇÃO SEGURA
  // ==========================================================

  const hashRecebidoBuffer =
    Buffer.from(
      v1,
      "utf8"
    );

  const hashCalculadoBuffer =
    Buffer.from(
      hashCalculado,
      "utf8"
    );

  if (
    hashRecebidoBuffer.length !==
    hashCalculadoBuffer.length
  ) {
    console.error(
      "❌ TAMANHO DOS HASHES DIFERENTE"
    );

    console.log(
      "========================================"
    );

    return false;
  }

  const valido =
    crypto.timingSafeEqual(
      hashRecebidoBuffer,
      hashCalculadoBuffer
    );

  if (valido) {
    console.log(
      "✅ ASSINATURA WEBHOOK VALIDADA"
    );
  } else {
    console.error(
      "❌ ASSINATURA WEBHOOK INVÁLIDA"
    );

    console.error(
      "⚠️ VERIFIQUE SE O WEBHOOK SECRET DO RENDER É O MESMO DO MERCADO PAGO."
    );
  }

  console.log(
    "========================================"
  );

  return valido;
}

// ============================================================
// LOCALIZAR PEDIDO FOODJET
// ============================================================

async function localizarPedido(
  dadosOrder
) {
  const referencia =
    dadosOrder?.external_reference;

  if (!referencia) {
    return null;
  }

  const pedidos =
    await Order.listar();

  if (!Array.isArray(pedidos)) {
    return null;
  }

  // ==========================================================
  // REFERÊNCIA EXATA
  // ==========================================================

  let pedido =
    pedidos.find(
      (item) =>
        String(item.id) ===
        String(referencia)
    );

  // ==========================================================
  // FOODJET-123
  // ==========================================================

  if (!pedido) {
    const referenciaString =
      String(referencia);

    const match =
      referenciaString.match(
        /FOODJET-(\d+)/
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
      `Pedido FoodJet ${pedido.id} não encontrado na lista.`
    );
  }

  pedidos[index] =
    pedido;

  const {
    db,
  } = require(
    "../config/database"
  );

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

  if (!pedido.restauranteId) {
    console.log(
      "⚠️ Pedido sem restauranteId."
    );

    return;
  }

  const sala =
    "restaurante_" +
    pedido.restauranteId;

  // ==========================================================
  // PAGAMENTO APROVADO
  // ==========================================================

  global.io
    .to(sala)
    .emit(
      "pagamento_aprovado",
      pedido
    );

  // ==========================================================
  // NOVO PEDIDO
  // ==========================================================

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
// WEBHOOK
// ============================================================

async function webhook(
  req,
  res
) {
  console.log(
    "========================================"
  );

  console.log(
    "🔔 FOODJET - WEBHOOK MERCADO PAGO"
  );

  console.log(
    "========================================"
  );

  console.log(
    "📅 RECEBIDO:",
    new Date().toISOString()
  );

  console.log(
    "📌 TYPE:",
    req.body?.type ||
    req.query?.type
  );

  console.log(
    "📌 ACTION:",
    req.body?.action
  );

  console.log(
    "🆔 DATA ID:",
    req.query?.["data.id"] ||
    req.body?.data?.id
  );

  console.log(
    "🌎 LIVE MODE:",
    req.body?.live_mode
  );

  console.log(
    "🔗 QUERY:",
    JSON.stringify(
      req.query
    )
  );

  try {
    // ========================================================
    // VALIDAR ASSINATURA
    // ========================================================

    const assinaturaValida =
      validarAssinatura(req);

    if (!assinaturaValida) {
      console.error(
        "❌ ASSINATURA WEBHOOK INVÁLIDA"
      );

      return res
        .status(401)
        .json({
          sucesso: false,
          erro:
            "Assinatura inválida.",
        });
    }

    console.log(
      "✅ ASSINATURA WEBHOOK VALIDADA"
    );

    // ========================================================
    // TIPO
    // ========================================================

    const tipo =
      req.body?.type ||
      req.query?.type;

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

    const orderId =
      req.query?.["data.id"];

    if (!orderId) {
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

    console.log(
      "🔎 CONSULTANDO ORDER:",
      orderId
    );

    // ========================================================
    // CONSULTAR ORDER
    // ========================================================

    const order =
      await consultarOrder(
        orderId
      );

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

    // ========================================================
    // PAYMENT
    // ========================================================

    const payment =
      order
        ?.transactions
        ?.payments
        ?.[0];

    const paymentStatus =
      payment?.status;

    const paymentDetail =
      payment?.status_detail;

    console.log(
      "🆔 PAYMENT ID:",
      payment?.id
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
      "========================================"
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
      order.status ===
        "processed" &&
      paymentStatus ===
        "processed" &&
      paymentDetail ===
        "accredited";

    if (aprovado) {
      // ======================================================
      // IDEMPOTÊNCIA
      // ======================================================

      if (
        pedido.pagamentoStatus ===
          "APROVADO" &&
        pedido.mercadoPagoOrderId ===
          order.id
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
      // PAGAMENTO
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

      // ======================================================
      // STATUS DO PEDIDO
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

      // ======================================================
      // SOCKET.IO
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
        order.status_detail;

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
        order.status_detail;

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
        order.status_detail;

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
    // RESPOSTA
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
        detalhes:
          erro?.message,
      });
  }
}

// ============================================================
// EXPORTAÇÃO
// ============================================================
//
// IMPORTANTE:
// Não usar "webhook: exports.webhook".
// Isso evita o ReferenceError que apareceu anteriormente.
//
// ============================================================

module.exports = {
  webhook,
};