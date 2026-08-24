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
 * verifica processed / accredited
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
  WEBHOOK_SECRET ? "CONFIGURADO" : "NÃO CONFIGURADO"
);

console.log("========================================");

// ============================================================
// VALIDAR ASSINATURA
// ============================================================

function validarAssinatura(req) {
  if (!WEBHOOK_SECRET) {
    throw new Error(
      "MERCADOPAGO_WEBHOOK_SECRET não configurado."
    );
  }

  const xSignature =
    req.headers["x-signature"];

  const xRequestId =
    req.headers["x-request-id"];

  if (!xSignature) {
    return false;
  }

  if (!xRequestId) {
    return false;
  }

  // ----------------------------------------------------------
  // data.id
  // ----------------------------------------------------------

  const dataId =
    req.query["data.id"] ||
    req.query.data_id ||
    req.body?.data?.id ||
    "";

  if (!dataId) {
    return false;
  }

  // ----------------------------------------------------------
  // Separar ts e v1
  // ----------------------------------------------------------

  const partes =
    xSignature.split(",");

  let ts = null;
  let hashRecebido = null;

  for (const parte of partes) {
    const [chave, ...resto] =
      parte.split("=");

    const valor =
      resto.join("=");

    if (!chave || !valor) {
      continue;
    }

    const chaveNormalizada =
      chave.trim();

    const valorNormalizado =
      valor.trim();

    if (chaveNormalizada === "ts") {
      ts = valorNormalizado;
    }

    if (chaveNormalizada === "v1") {
      hashRecebido =
        valorNormalizado;
    }
  }

  if (!ts || !hashRecebido) {
    return false;
  }

  // ----------------------------------------------------------
  // Manifest
  // ----------------------------------------------------------
  //
  // Mercado Pago:
  //
  // id:[data.id];
  // request-id:[x-request-id];
  // ts:[ts];
  //
  // ----------------------------------------------------------

  const manifest =
    `id:${dataId};` +
    `request-id:${xRequestId};` +
    `ts:${ts};`;

  // ----------------------------------------------------------
  // HMAC SHA256
  // ----------------------------------------------------------

  const hashCalculado =
    crypto
      .createHmac(
        "sha256",
        WEBHOOK_SECRET
      )
      .update(manifest)
      .digest("hex");

  // ----------------------------------------------------------
  // Comparação segura
  // ----------------------------------------------------------

  const recebido =
    Buffer.from(
      hashRecebido,
      "utf8"
    );

  const calculado =
    Buffer.from(
      hashCalculado,
      "utf8"
    );

  if (
    recebido.length !==
    calculado.length
  ) {
    return false;
  }

  return crypto.timingSafeEqual(
    recebido,
    calculado
  );
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

  // ----------------------------------------------------------
  // A referência criada pelo FoodJet deverá ser o ID do pedido
  // ou conter o ID do pedido.
  // ----------------------------------------------------------

  let pedido =
    pedidos.find(
      (item) =>
        String(item.id) ===
        String(referencia)
    );

  // ----------------------------------------------------------
  // Caso a referência esteja no formato FOODJET-123
  // ----------------------------------------------------------

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

  const { db } =
    require("../config/database");

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

  // ----------------------------------------------------------
  // Evento de pagamento confirmado
  // ----------------------------------------------------------

  global.io
    .to(sala)
    .emit(
      "pagamento_aprovado",
      pedido
    );

  // ----------------------------------------------------------
  // Evento de novo pedido
  //
  // Isso permite que o restaurante receba o pedido
  // somente depois da confirmação do pagamento.
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
// WEBHOOK
// ============================================================

exports.webhook = async (
  req,
  res
) => {
  console.log("========================================");
  console.log("🔔 FOODJET - WEBHOOK MERCADO PAGO");
  console.log("========================================");

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
    req.body?.data?.id ||
    req.query?.["data.id"]
  );

  console.log(
    "🌎 LIVE MODE:",
    req.body?.live_mode
  );

  // ==========================================================
  // RESPONDER RÁPIDO AO MERCADO PAGO
  // ==========================================================
  //
  // A documentação recomenda HTTP 200/201 para confirmar
  // recebimento da notificação.
  //
  // Primeiro validamos a assinatura e depois processamos.
  //
  // ==========================================================

  try {
    // --------------------------------------------------------
    // VALIDAR ASSINATURA
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // VALIDAR TIPO
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // ORDER ID
    // --------------------------------------------------------

    const orderId =
      req.body?.data?.id ||
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

    // --------------------------------------------------------
    // CONSULTAR ORDER NO MERCADO PAGO
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // PAYMENT
    // --------------------------------------------------------

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
    // LOCALIZAR PEDIDO FOODJET
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

      // Recebe a notificação para evitar retries
      // infinitos enquanto investigamos a referência.

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
      // STATUS DO PEDIDO
      // ------------------------------------------------------
      //
      // O restaurante trabalha com:
      //
      // AGUARDANDO_RESTAURANTE
      // ACEITO
      // PREPARANDO
      // PRONTO
      // EM_ENTREGA
      // ENTREGUE
      //
      // Portanto, depois do pagamento aprovado:
      //
      // AGUARDANDO_RESTAURANTE
      //
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
          pedidoId: pedido.id,
        });
    }

    // ========================================================
    // OUTROS STATUS
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

      pedido.atualizadoEm =
        new Date().toISOString();

      await salvarPedidoAtualizado(
        pedido
      );

      console.log(
        "⏳ PIX AINDA PENDENTE"
      );
    }

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

      pedido.atualizadoEm =
        new Date().toISOString();

      await salvarPedidoAtualizado(
        pedido
      );

      console.log(
        "❌ PAGAMENTO FALHOU"
      );
    }

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

      pedido.atualizadoEm =
        new Date().toISOString();

      await salvarPedidoAtualizado(
        pedido
      );

      console.log(
        "❌ PAGAMENTO CANCELADO/EXPIRADO"
      );
    }

    return res
      .status(200)
      .json({
        recebido: true,
        pagamentoAprovado: false,
        status: order.status,
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
      erro
    );

    console.error(
      "========================================"
    );

    // Retornamos 500 para que o Mercado Pago possa
    // tentar novamente quando houver falha real no
    // processamento.

    return res
      .status(500)
      .json({
        sucesso: false,
        erro:
          "Erro ao processar webhook.",
        detalhes:
          erro.message,
      });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  webhook,
};