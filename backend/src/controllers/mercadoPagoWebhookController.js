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
 * localiza pedido FoodJet
 *      ↓
 * verifica pagamento
 *      ↓
 * atualiza foodjet.json
 *      ↓
 * Socket.IO
 *      ↓
 * restaurante recebe pedido
 *
 * ============================================================
 */

require("dotenv").config({
  override: true,
});

const crypto = require("crypto");

const Order = require("../models/order");

const {
  consultarOrder,
} = require("../services/mercadoPagoService");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const WEBHOOK_SECRET =
  String(
    process.env.MERCADOPAGO_WEBHOOK_SECRET || ""
  ).trim();

// ============================================================
// LOG INICIAL
// ============================================================

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
  "WEBHOOK SECRET:",
  WEBHOOK_SECRET
    ? "CONFIGURADO"
    : "NÃO CONFIGURADO"
);

console.log(
  "========================================"
);

// ============================================================
// FUNÇÃO PARA OBTER DATA.ID
// ============================================================
//
// O Mercado Pago normalmente envia:
//
// ?data.id=ORDER_ID
//
// Mas também podemos receber:
//
// body.data.id
//
// ============================================================

function obterDataId(req) {
  return (
    req.query?.["data.id"] ||
    req.body?.data?.id ||
    req.body?.data_id ||
    null
  );
}

// ============================================================
// EXTRAIR ASSINATURA
// ============================================================

function extrairAssinatura(xSignature) {
  let ts = null;
  let v1 = null;

  if (!xSignature) {
    return {
      ts: null,
      v1: null,
    };
  }

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
        .trim()
        .toLowerCase();

    const valor =
      parte
        .substring(indice + 1)
        .trim();

    if (chave === "ts") {
      ts = valor;
    }

    if (chave === "v1") {
      v1 = valor;
    }
  }

  return {
    ts,
    v1,
  };
}

// ============================================================
// VALIDAR ASSINATURA MERCADO PAGO
// ============================================================
//
// Documentação Mercado Pago:
//
// manifest:
// id:<data.id>;
// request-id:<x-request-id>;
// ts:<ts>;
//
// HMAC SHA256
//
// ============================================================

function validarAssinatura(req) {
  console.log(
    "========================================"
  );

  console.log(
    "🔐 VALIDANDO ASSINATURA WEBHOOK"
  );

  console.log(
    "========================================"
  );

  // ----------------------------------------------------------
  // SECRET
  // ----------------------------------------------------------

  if (!WEBHOOK_SECRET) {
    console.error(
      "❌ MERCADOPAGO_WEBHOOK_SECRET NÃO CONFIGURADO"
    );

    return false;
  }

  // ----------------------------------------------------------
  // HEADERS
  // ----------------------------------------------------------

  const xSignature =
    req.headers["x-signature"];

  const xRequestId =
    req.headers["x-request-id"];

  // ----------------------------------------------------------
  // DATA ID
  // ----------------------------------------------------------

  const dataId =
    obterDataId(req);

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
  // EXTRAIR TS / V1
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // MANIFEST
  // ----------------------------------------------------------

  const manifest =
    `id:${dataId};` +
    `request-id:${xRequestId};` +
    `ts:${ts};`;

  console.log(
    "MANIFEST:",
    manifest
  );

  // ----------------------------------------------------------
  // HMAC SHA256
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // NORMALIZAÇÃO
  // ----------------------------------------------------------

  const recebido =
    String(v1)
      .trim()
      .toLowerCase();

  const calculado =
    String(hashCalculado)
      .trim()
      .toLowerCase();

  // ----------------------------------------------------------
  // TAMANHO
  // ----------------------------------------------------------

  if (
    recebido.length !==
    calculado.length
  ) {
    console.error(
      "❌ TAMANHO DOS HASHES DIFERENTE"
    );

    console.error(
      "TAMANHO RECEBIDO:",
      recebido.length
    );

    console.error(
      "TAMANHO CALCULADO:",
      calculado.length
    );

    return false;
  }

  // ----------------------------------------------------------
  // COMPARAÇÃO SEGURA
  // ----------------------------------------------------------

  const hashRecebidoBuffer =
    Buffer.from(
      recebido,
      "utf8"
    );

  const hashCalculadoBuffer =
    Buffer.from(
      calculado,
      "utf8"
    );

  const valido =
    crypto.timingSafeEqual(
      hashRecebidoBuffer,
      hashCalculadoBuffer
    );

  if (valido) {
    console.log(
      "========================================"
    );

    console.log(
      "✅ ASSINATURA WEBHOOK VALIDADA"
    );

    console.log(
      "========================================"
    );

    return true;
  }

  console.error(
    "========================================"
  );

  console.error(
    "❌ ASSINATURA WEBHOOK INVÁLIDA"
  );

  console.error(
    "⚠️ O SECRET UTILIZADO PELO FOODJET NÃO PRODUZIU O MESMO HASH."
  );

  console.error(
    "⚠️ CONFIRA O SECRET DA MESMA APLICAÇÃO DO MERCADO PAGO."
  );

  console.error(
    "========================================"
  );

  return false;
}

// ============================================================
// LOCALIZAR PEDIDO FOODJET
// ============================================================

async function localizarPedido(
  dadosOrder,
  referenciaWebhook = null
) {
  // ----------------------------------------------------------
  // PRIMEIRO: external_reference DA ORDER
  // ----------------------------------------------------------

  let referencia =
    dadosOrder?.external_reference;

  // ----------------------------------------------------------
  // FALLBACK: BODY DO WEBHOOK
  // ----------------------------------------------------------

  if (!referencia) {
    referencia =
      referenciaWebhook;
  }

  if (!referencia) {
    console.log(
      "⚠️ EXTERNAL_REFERENCE NÃO ENCONTRADO"
    );

    return null;
  }

  console.log(
    "🔎 EXTERNAL_REFERENCE:",
    referencia
  );

  // ----------------------------------------------------------
  // LISTAR PEDIDOS
  // ----------------------------------------------------------

  const pedidos =
    await Order.listar();

  if (!Array.isArray(pedidos)) {
    console.error(
      "❌ LISTA DE PEDIDOS INVÁLIDA"
    );

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
      const idFoodJet =
        match[1];

      pedido =
        pedidos.find(
          (item) =>
            String(item.id) ===
            String(idFoodJet)
        );
    }
  }

  // ----------------------------------------------------------
  // RESULTADO
  // ----------------------------------------------------------

  if (pedido) {
    console.log(
      "✅ PEDIDO FOODJET LOCALIZADO:",
      pedido.id
    );
  } else {
    console.error(
      "⚠️ PEDIDO FOODJET NÃO ENCONTRADO"
    );
  }

  return pedido || null;
}

// ============================================================
// SALVAR PEDIDO
// ============================================================

async function salvarPedidoAtualizado(
  pedido
) {
  if (!pedido?.id) {
    throw new Error(
      "Pedido sem ID não pode ser salvo."
    );
  }

  const pedidos =
    await Order.listar();

  if (!Array.isArray(pedidos)) {
    throw new Error(
      "Lista de pedidos inválida."
    );
  }

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

  // ----------------------------------------------------------
  // BANCO
  // ----------------------------------------------------------

  const {
    db,
  } = require(
    "../config/database"
  );

  await db.write();

  console.log(
    "💾 PEDIDO SALVO NO BANCO:",
    pedido.id
  );

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
      "⚠️ SOCKET.IO NÃO DISPONÍVEL"
    );

    return;
  }

  if (!pedido?.restauranteId) {
    console.log(
      "⚠️ PEDIDO SEM restauranteId"
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
    "📡 SOCKET.IO - PEDIDO ENVIADO"
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
// ATUALIZAR DADOS DO MERCADO PAGO
// ============================================================

function atualizarDadosMercadoPago(
  pedido,
  order,
  payment
) {
  pedido.mercadoPagoOrderId =
    order?.id ||
    pedido.mercadoPagoOrderId ||
    null;

  pedido.mercadoPagoPaymentId =
    payment?.id ||
    pedido.mercadoPagoPaymentId ||
    null;

  pedido.mercadoPagoOrderStatus =
    order?.status ||
    null;

  pedido.mercadoPagoOrderStatusDetail =
    order?.status_detail ||
    null;

  pedido.pagamentoStatusDetalhe =
    payment?.status_detail ||
    order?.status_detail ||
    pedido.pagamentoStatusDetalhe ||
    null;

  pedido.pagamentoMetodo =
    "PIX";

  pedido.atualizadoEm =
    new Date().toISOString();
}

// ============================================================
// PAGAMENTO APROVADO
// ============================================================

async function processarPagamentoAprovado(
  pedido,
  order,
  payment
) {
  // ----------------------------------------------------------
  // IDEMPOTÊNCIA
  // ----------------------------------------------------------

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

    return {
      jaProcessado: true,
    };
  }

  // ----------------------------------------------------------
  // DADOS DO PAGAMENTO
  // ----------------------------------------------------------

  pedido.pagamentoStatus =
    "APROVADO";

  pedido.pagamentoStatusDetalhe =
    payment?.status_detail ||
    order.status_detail ||
    "accredited";

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

  // ----------------------------------------------------------
  // STATUS FOODJET
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // SALVAR
  // ----------------------------------------------------------

  await salvarPedidoAtualizado(
    pedido
  );

  // ----------------------------------------------------------
  // LOG
  // ----------------------------------------------------------

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
    "📌 STATUS FOODJET:",
    pedido.status
  );

  console.log(
    "========================================"
  );

  // ----------------------------------------------------------
  // RESTAURANTE
  // ----------------------------------------------------------

  notificarRestaurante(
    pedido
  );

  return {
    jaProcessado: false,
  };
}

// ============================================================
// PAGAMENTO PENDENTE
// ============================================================

async function processarPagamentoPendente(
  pedido,
  order,
  payment
) {
  pedido.pagamentoStatus =
    "PENDENTE";

  atualizarDadosMercadoPago(
    pedido,
    order,
    payment
  );

  pedido.pagamentoAprovado =
    false;

  await salvarPedidoAtualizado(
    pedido
  );

  console.log(
    "========================================"
  );

  console.log(
    "⏳ PAGAMENTO AINDA PENDENTE"
  );

  console.log(
    "🆔 PEDIDO:",
    pedido.id
  );

  console.log(
    "📊 ORDER STATUS:",
    order.status
  );

  console.log(
    "📋 STATUS DETAIL:",
    order.status_detail
  );

  console.log(
    "========================================"
  );
}

// ============================================================
// PAGAMENTO FALHOU
// ============================================================

async function processarPagamentoFalhou(
  pedido,
  order,
  payment
) {
  pedido.pagamentoStatus =
    "FALHOU";

  atualizarDadosMercadoPago(
    pedido,
    order,
    payment
  );

  pedido.pagamentoAprovado =
    false;

  await salvarPedidoAtualizado(
    pedido
  );

  console.log(
    "========================================"
  );

  console.log(
    "❌ PAGAMENTO FALHOU"
  );

  console.log(
    "🆔 PEDIDO:",
    pedido.id
  );

  console.log(
    "📊 STATUS:",
    order.status
  );

  console.log(
    "📋 DETAIL:",
    order.status_detail
  );

  console.log(
    "========================================"
  );
}

// ============================================================
// PAGAMENTO CANCELADO / EXPIRADO
// ============================================================

async function processarPagamentoCancelado(
  pedido,
  order,
  payment
) {
  pedido.pagamentoStatus =
    "CANCELADO";

  atualizarDadosMercadoPago(
    pedido,
    order,
    payment
  );

  pedido.pagamentoAprovado =
    false;

  await salvarPedidoAtualizado(
    pedido
  );

  console.log(
    "========================================"
  );

  console.log(
    "❌ PAGAMENTO CANCELADO / EXPIRADO"
  );

  console.log(
    "🆔 PEDIDO:",
    pedido.id
  );

  console.log(
    "📊 STATUS:",
    order.status
  );

  console.log(
    "📋 DETAIL:",
    order.status_detail
  );

  console.log(
    "========================================"
  );
}

// ============================================================
// WEBHOOK PRINCIPAL
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

  // ----------------------------------------------------------
  // DADOS DO WEBHOOK
  // ----------------------------------------------------------

  const tipo =
    req.body?.type ||
    req.query?.type ||
    null;

  const action =
    req.body?.action ||
    null;

  const dataId =
    obterDataId(req);

  const externalReferenceWebhook =
    req.query?.["data.external_reference"] ||
    req.body?.data?.external_reference ||
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
    externalReferenceWebhook ||
      "NÃO RECEBIDO"
  );

  console.log(
    "🌎 LIVE MODE:",
    req.body?.live_mode
  );

  console.log(
    "🔗 QUERY:",
    JSON.stringify(
      req.query || {}
    )
  );

  try {
    // ========================================================
    // 1. VALIDAR ASSINATURA
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

    console.log(
      "✅ ASSINATURA WEBHOOK VALIDADA"
    );

    // ========================================================
    // 2. TIPO
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
          tipo,
        });
    }

    // ========================================================
    // 3. ORDER ID
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

    console.log(
      "🔎 CONSULTANDO ORDER:",
      dataId
    );

    // ========================================================
    // 4. CONSULTAR ORDER NO MERCADO PAGO
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
    // 5. PAYMENT
    // ========================================================

    const payment =
      order
        ?.transactions
        ?.payments
        ?.[0] || null;

    const paymentStatus =
      payment?.status ||
      null;

    const paymentDetail =
      payment?.status_detail ||
      null;

    console.log(
      "🆔 PAYMENT ID:",
      payment?.id ||
        "NÃO INFORMADO"
    );

    console.log(
      "📊 PAYMENT STATUS:",
      paymentStatus ||
        "NÃO INFORMADO"
    );

    console.log(
      "📋 PAYMENT DETAIL:",
      paymentDetail ||
        "NÃO INFORMADO"
    );

    // ========================================================
    // 6. LOCALIZAR PEDIDO FOODJET
    // ========================================================

    const pedido =
      await localizarPedido(
        order,
        externalReferenceWebhook
      );

    if (!pedido) {
      console.error(
        "⚠️ PEDIDO FOODJET NÃO ENCONTRADO"
      );

      console.error(
        "EXTERNAL REFERENCE ORDER:",
        order.external_reference
      );

      console.error(
        "EXTERNAL REFERENCE WEBHOOK:",
        externalReferenceWebhook
      );

      // ------------------------------------------------------
      // IMPORTANTE:
      // Mercado Pago recebeu o webhook corretamente.
      // Não devemos ficar retornando 500.
      // ------------------------------------------------------

      return res
        .status(200)
        .json({
          recebido: true,
          pedidoEncontrado: false,
        });
    }

    console.log(
      "========================================"
    );

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

    console.log(
      "💳 PAGAMENTO ATUAL:",
      pedido.pagamentoStatus
    );

    console.log(
      "========================================"
    );

    // ========================================================
    // 7. PROCESSAR STATUS
    // ========================================================

    // --------------------------------------------------------
    // APROVADO
    // --------------------------------------------------------

    const aprovado =
      order.status ===
        "processed" &&
      paymentStatus ===
        "processed" &&
      paymentDetail ===
        "accredited";

    if (aprovado) {
      const resultado =
        await processarPagamentoAprovado(
          pedido,
          order,
          payment
        );

      return res
        .status(200)
        .json({
          recebido: true,
          pagamentoAprovado: true,
          pedidoAtualizado:
            !resultado.jaProcessado,
          jaProcessado:
            resultado.jaProcessado,
          pedidoId:
            pedido.id,
        });
    }

    // --------------------------------------------------------
    // PENDENTE / ACTION REQUIRED
    // --------------------------------------------------------

    if (
      order.status ===
        "action_required" ||
      order.status ===
        "created"
    ) {
      await processarPagamentoPendente(
        pedido,
        order,
        payment
      );

      return res
        .status(200)
        .json({
          recebido: true,
          pagamentoAprovado: false,
          pagamentoPendente: true,
          status:
            order.status,
          statusDetail:
            order.status_detail,
          pedidoId:
            pedido.id,
        });
    }

    // --------------------------------------------------------
    // FALHOU
    // --------------------------------------------------------

    if (
      order.status ===
        "failed"
    ) {
      await processarPagamentoFalhou(
        pedido,
        order,
        payment
      );

      return res
        .status(200)
        .json({
          recebido: true,
          pagamentoAprovado: false,
          pagamentoFalhou: true,
          status:
            order.status,
          statusDetail:
            order.status_detail,
          pedidoId:
            pedido.id,
        });
    }

    // --------------------------------------------------------
    // CANCELADO
    // --------------------------------------------------------

    if (
      order.status ===
        "cancelled" ||
      order.status ===
        "canceled" ||
      order.status ===
        "expired"
    ) {
      await processarPagamentoCancelado(
        pedido,
        order,
        payment
      );

      return res
        .status(200)
        .json({
          recebido: true,
          pagamentoAprovado: false,
          pagamentoCancelado: true,
          status:
            order.status,
          statusDetail:
            order.status_detail,
          pedidoId:
            pedido.id,
        });
    }

    // ========================================================
    // 8. OUTROS STATUS
    // ========================================================

    console.log(
      "ℹ️ STATUS NÃO TRATADO:",
      order.status
    );

    atualizarDadosMercadoPago(
      pedido,
      order,
      payment
    );

    await salvarPedidoAtualizado(
      pedido
    );

    return res
      .status(200)
      .json({
        recebido: true,
        pagamentoAprovado: false,
        status:
          order.status,
        statusDetail:
          order.status_detail,
        pedidoId:
          pedido.id,
      });

  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO NO WEBHOOK MERCADO PAGO"
    );

    console.error(
      "========================================"
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

module.exports = {
  webhook,
};