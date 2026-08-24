
/**
 * ============================================================
 * FOODJET - MERCADO PAGO SERVICE
 * ============================================================
 *
 * PIX REAL - MERCADO PAGO ORDERS API
 *
 * AMBIENTE:
 * - PRODUÇÃO
 *
 * ENDPOINT:
 * https://api.mercadopago.com/v1/orders
 *
 * RECURSOS:
 * - Criação de Order PIX REAL
 * - X-Idempotency-Key
 * - QR Code
 * - QR Code Base64
 * - Ticket URL
 * - Consulta da Order
 * - Cancelamento da Order
 *
 * IMPORTANTE:
 * - O Access Token fica SOMENTE no backend.
 * - Nunca coloque o Access Token no Flutter.
 * - Nunca envie o Access Token para o GitHub.
 * - O .env deve permanecer protegido.
 *
 * ============================================================
 */

require("dotenv").config({ override: true });

const crypto = require("crypto");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const ACCESS_TOKEN =
  process.env.MERCADOPAGO_ACCESS_TOKEN?.trim();

const ENVIRONMENT =
  process.env.MERCADOPAGO_ENVIRONMENT?.trim().toLowerCase() ||
  "production";

const API_URL =
  "https://api.mercadopago.com/v1/orders";

// ============================================================
// LOG INICIAL
// ============================================================

console.log("========================================");
console.log("🔐 MERCADO PAGO - FOODJET");
console.log("========================================");

console.log(
  "TOKEN CARREGADO:",
  ACCESS_TOKEN ? "SIM" : "NÃO"
);

console.log(
  "AMBIENTE:",
  ENVIRONMENT
);

console.log(
  "API:",
  API_URL
);

console.log("========================================");

// ============================================================
// VALIDAÇÃO DE AMBIENTE
// ============================================================

if (ENVIRONMENT !== "production") {
  console.error("❌ AMBIENTE INVÁLIDO");
  console.error(
    "O Mercado Pago Service do FoodJet está configurado exclusivamente para PRODUÇÃO."
  );

  throw new Error(
    "MERCADOPAGO_ENVIRONMENT deve ser 'production'."
  );
}

// ============================================================
// VALIDAÇÃO DO TOKEN
// ============================================================

if (!ACCESS_TOKEN) {
  console.error(
    "❌ MERCADOPAGO_ACCESS_TOKEN NÃO CONFIGURADO NO .ENV"
  );

  throw new Error(
    "MERCADOPAGO_ACCESS_TOKEN não configurado."
  );
}

// ============================================================
// IDEMPOTENCY KEY
// ============================================================

function gerarIdempotencyKey() {
  return crypto.randomUUID();
}

// ============================================================
// NORMALIZAR VALOR
// ============================================================

function normalizarValor(valor) {
  const valorNumerico = Number(valor);

  if (
    !Number.isFinite(valorNumerico) ||
    valorNumerico <= 0
  ) {
    throw new Error(
      `Valor inválido para PIX: ${valor}`
    );
  }

  return valorNumerico;
}

// ============================================================
// VALIDAR E-MAIL REAL
// ============================================================

function validarEmail(email) {
  if (!email || typeof email !== "string") {
    throw new Error(
      "E-mail do pagador não informado."
    );
  }

  const emailNormalizado =
    email.trim().toLowerCase();

  // Validação simples para evitar envio
  // de e-mail obviamente inválido.

  const emailValido =
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(
      emailNormalizado
    );

  if (!emailValido) {
    throw new Error(
      "E-mail do pagador inválido."
    );
  }

  return emailNormalizado;
}

// ============================================================
// VALIDAR REFERÊNCIA
// ============================================================

function validarReferencia(referencia) {
  if (
    !referencia ||
    typeof referencia !== "string"
  ) {
    throw new Error(
      "Referência externa não informada."
    );
  }

  const referenciaNormalizada =
    referencia.trim();

  if (!referenciaNormalizada) {
    throw new Error(
      "Referência externa inválida."
    );
  }

  // A documentação da Orders API limita
  // external_reference a 64 caracteres.

  if (referenciaNormalizada.length > 64) {
    throw new Error(
      "A referência externa deve possuir no máximo 64 caracteres."
    );
  }

  return referenciaNormalizada;
}

// ============================================================
// CRIAR PIX REAL
// ============================================================

async function criarPix({
  valor,
  email,
  referencia,
  descricao,
}) {
  console.log("========================================");
  console.log("💳 FOODJET - GERAR PIX REAL");
  console.log("========================================");

  // ----------------------------------------------------------
  // TOKEN
  // ----------------------------------------------------------

  if (!ACCESS_TOKEN) {
    throw new Error(
      "MERCADOPAGO_ACCESS_TOKEN não configurado."
    );
  }

  // ----------------------------------------------------------
  // AMBIENTE
  // ----------------------------------------------------------

  if (ENVIRONMENT !== "production") {
    throw new Error(
      "FoodJet configurado para aceitar somente ambiente de produção."
    );
  }

  // ----------------------------------------------------------
  // VALOR
  // ----------------------------------------------------------

  const valorNumerico =
    normalizarValor(valor);

  // ----------------------------------------------------------
  // E-MAIL REAL
  // ----------------------------------------------------------

  const emailNormalizado =
    validarEmail(email);

  // ----------------------------------------------------------
  // REFERÊNCIA
  // ----------------------------------------------------------

  const referenciaFinal =
    validarReferencia(
      referencia ||
      `FOODJET-${Date.now()}`
    );

  // ----------------------------------------------------------
  // DESCRIÇÃO
  // ----------------------------------------------------------

  const descricaoFinal =
    descricao ||
    `Pedido FoodJet #${referenciaFinal}`;

  // ----------------------------------------------------------
  // IDEMPOTENCY
  // ----------------------------------------------------------

  const idempotencyKey =
    gerarIdempotencyKey();

  // ----------------------------------------------------------
  // LOG
  // ----------------------------------------------------------

  console.log(
    "💰 VALOR:",
    valorNumerico.toFixed(2)
  );

  console.log(
    "📧 PAGADOR:",
    emailNormalizado
  );

  console.log(
    "📦 REFERÊNCIA:",
    referenciaFinal
  );

  console.log(
    "📝 DESCRIÇÃO:",
    descricaoFinal
  );

  console.log(
    "🌎 AMBIENTE:",
    "PRODUÇÃO"
  );

  console.log(
    "🔑 IDEMPOTENCY KEY:",
    idempotencyKey
  );

  console.log("========================================");

  // ==========================================================
  // PAYLOAD ORDERS API - PRODUÇÃO
  // ==========================================================

  const body = {
    type: "online",

    processing_mode: "automatic",

    total_amount:
      valorNumerico.toFixed(2),

    external_reference:
      referenciaFinal,

    transactions: {
      payments: [
        {
          amount:
            valorNumerico.toFixed(2),

          payment_method: {
            id: "pix",
            type: "bank_transfer",
          },
        },
      ],
    },

    // ========================================================
    // PAYER REAL
    // ========================================================
    //
    // NÃO existe:
    // first_name: "APRO"
    // last_name: "TESTE"
    //
    // Esses dados eram utilizados no ambiente de teste.
    // ========================================================

    payer: {
      email:
        emailNormalizado,
    },
  };

  // ==========================================================
  // LOG PAYLOAD
  // ==========================================================

  console.log(
    "📤 PAYLOAD ORDERS - PRODUÇÃO:"
  );

  console.log(
    JSON.stringify(
      body,
      null,
      2
    )
  );

  console.log("========================================");

  // ==========================================================
  // REQUISIÇÃO
  // ==========================================================

  let resposta;

  try {
    resposta =
      await fetch(
        API_URL,
        {
          method: "POST",

          headers: {
            Authorization:
              `Bearer ${ACCESS_TOKEN}`,

            "Content-Type":
              "application/json",

            "X-Idempotency-Key":
              idempotencyKey,
          },

          body:
            JSON.stringify(body),
        }
      );
  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO DE CONEXÃO MERCADO PAGO"
    );

    console.error(
      erro
    );

    console.error(
      "========================================"
    );

    throw new Error(
      `Falha de conexão com Mercado Pago: ${erro.message}`
    );
  }

  // ==========================================================
  // RESPOSTA
  // ==========================================================

  const texto =
    await resposta.text();

  let dados;

  try {
    dados =
      texto
        ? JSON.parse(texto)
        : {};
  } catch {
    dados = {
      raw: texto,
    };
  }

  // ==========================================================
  // ERRO
  // ==========================================================

  if (!resposta.ok) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO MERCADO PAGO - ORDERS API"
    );

    console.error(
      "🌎 AMBIENTE: PRODUÇÃO"
    );

    console.error(
      "STATUS:",
      resposta.status
    );

    console.error(
      "RESPOSTA:"
    );

    console.error(
      JSON.stringify(
        dados,
        null,
        2
      )
    );

    console.error(
      "========================================"
    );

    const erro =
      new Error(
        dados?.message ||
        dados?.error ||
        "Mercado Pago API error"
      );

    erro.status =
      resposta.status;

    erro.causes =
      dados?.errors ||
      dados?.causes ||
      [];

    erro.response =
      dados;

    throw erro;
  }

  // ==========================================================
  // ORDER CRIADA
  // ==========================================================

  console.log(
    "========================================"
  );

  console.log(
    "✅ PIX REAL CRIADO COM SUCESSO"
  );

  console.log(
    "========================================"
  );

  console.log(
    "🆔 ORDER ID:",
    dados.id
  );

  console.log(
    "📊 ORDER STATUS:",
    dados.status
  );

  console.log(
    "📋 STATUS DETAIL:",
    dados.status_detail
  );

  // ==========================================================
  // PAGAMENTO
  // ==========================================================

  const payment =
    dados?.transactions?.payments?.[0];

  if (!payment) {
    console.error(
      "⚠️ transactions.payments[0] não retornado."
    );

    throw new Error(
      "Pagamento PIX não retornado pela Orders API."
    );
  }

  // ==========================================================
  // PAYMENT METHOD
  // ==========================================================

  const paymentMethod =
    payment.payment_method || {};

  // ==========================================================
  // PIX
  // ==========================================================

  const qrCode =
    paymentMethod.qr_code ||
    null;

  const qrCodeBase64 =
    paymentMethod.qr_code_base64 ||
    null;

  const ticketUrl =
    paymentMethod.ticket_url ||
    null;

  // ==========================================================
  // LOG PAGAMENTO
  // ==========================================================

  console.log(
    "🆔 PAYMENT ID:",
    payment.id
  );

  console.log(
    "📊 PAYMENT STATUS:",
    payment.status
  );

  console.log(
    "📋 PAYMENT DETAIL:",
    payment.status_detail
  );

  console.log(
    "🔑 QR CODE:",
    qrCode
      ? "SIM"
      : "NÃO"
  );

  console.log(
    "🖼️ QR CODE BASE64:",
    qrCodeBase64
      ? "SIM"
      : "NÃO"
  );

  console.log(
    "🔗 TICKET URL:",
    ticketUrl
      ? "SIM"
      : "NÃO"
  );

  console.log(
    "⏰ EXPIRAÇÃO:",
    payment.date_of_expiration ||
    "não informado"
  );

  console.log(
    "========================================"
  );

  // ==========================================================
  // RETORNO FOODJET
  // ==========================================================

  return {
    // --------------------------------------------------------
    // ORDER
    // --------------------------------------------------------

    id:
      dados.id,

    order_id:
      dados.id,

    status:
      dados.status,

    status_detail:
      dados.status_detail,

    external_reference:
      dados.external_reference,

    total_amount:
      dados.total_amount,

    currency:
      dados.currency,

    // --------------------------------------------------------
    // PAYMENT
    // --------------------------------------------------------

    payment_id:
      payment.id,

    payment_status:
      payment.status,

    payment_status_detail:
      payment.status_detail,

    payment_amount:
      payment.amount,

    // --------------------------------------------------------
    // PIX
    // --------------------------------------------------------

    qr_code:
      qrCode,

    qr_code_base64:
      qrCodeBase64,

    ticket_url:
      ticketUrl,

    // --------------------------------------------------------
    // EXPIRAÇÃO
    // --------------------------------------------------------

    date_of_expiration:
      payment.date_of_expiration ||
      null,

    // --------------------------------------------------------
    // PAYMENT METHOD
    // --------------------------------------------------------

    payment_method:
      paymentMethod,

    // --------------------------------------------------------
    // TRANSACTIONS
    // --------------------------------------------------------

    transactions:
      dados.transactions,

    // --------------------------------------------------------
    // DADOS COMPLETOS
    // --------------------------------------------------------

    raw:
      dados,
  };
}

// ============================================================
// CONSULTAR ORDER
// ============================================================

async function consultarOrder(orderId) {
  if (!ACCESS_TOKEN) {
    throw new Error(
      "MERCADOPAGO_ACCESS_TOKEN não configurado."
    );
  }

  if (!orderId) {
    throw new Error(
      "orderId não informado."
    );
  }

  console.log(
    "========================================"
  );

  console.log(
    "🔎 FOODJET - CONSULTAR ORDER"
  );

  console.log(
    "🌎 AMBIENTE: PRODUÇÃO"
  );

  console.log(
    "🆔 ORDER ID:",
    orderId
  );

  console.log(
    "========================================"
  );

  let resposta;

  try {
    resposta =
      await fetch(
        `${API_URL}/${encodeURIComponent(orderId)}`,
        {
          method: "GET",

          headers: {
            Authorization:
              `Bearer ${ACCESS_TOKEN}`,

            "Content-Type":
              "application/json",
          },
        }
      );
  } catch (erro) {
    console.error(
      "❌ ERRO AO CONSULTAR ORDER:"
    );

    console.error(
      erro
    );

    throw new Error(
      `Falha de conexão ao consultar Order: ${erro.message}`
    );
  }

  const texto =
    await resposta.text();

  let dados;

  try {
    dados =
      texto
        ? JSON.parse(texto)
        : {};
  } catch {
    dados = {
      raw: texto,
    };
  }

  if (!resposta.ok) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO AO CONSULTAR ORDER"
    );

    console.error(
      "STATUS:",
      resposta.status
    );

    console.error(
      JSON.stringify(
        dados,
        null,
        2
      )
    );

    console.error(
      "========================================"
    );

    const erro =
      new Error(
        dados?.message ||
        dados?.error ||
        "Erro ao consultar Order"
      );

    erro.status =
      resposta.status;

    erro.response =
      dados;

    erro.causes =
      dados?.errors ||
      dados?.causes ||
      [];

    throw erro;
  }

  // ==========================================================
  // EXTRAIR PAGAMENTO
  // ==========================================================

  const payment =
    dados?.transactions?.payments?.[0] ||
    null;

  // ==========================================================
  // LOG
  // ==========================================================

  console.log(
    "========================================"
  );

  console.log(
    "✅ ORDER CONSULTADA"
  );

  console.log(
    "========================================"
  );

  console.log(
    "🆔 ORDER ID:",
    dados.id
  );

  console.log(
    "📊 ORDER STATUS:",
    dados.status
  );

  console.log(
    "📋 ORDER DETAIL:",
    dados.status_detail
  );

  if (payment) {
    console.log(
      "🆔 PAYMENT ID:",
      payment.id
    );

    console.log(
      "📊 PAYMENT STATUS:",
      payment.status
    );

    console.log(
      "📋 PAYMENT DETAIL:",
      payment.status_detail
    );
  }

  console.log(
    "========================================"
  );

  return dados;
}

// ============================================================
// CANCELAR ORDER
// ============================================================
//
// Orders API atual:
// POST /v1/orders/{order_id}/cancel
//
// ============================================================

async function cancelarOrder(orderId) {
  if (!ACCESS_TOKEN) {
    throw new Error(
      "MERCADOPAGO_ACCESS_TOKEN não configurado."
    );
  }

  if (!orderId) {
    throw new Error(
      "orderId não informado."
    );
  }

  console.log(
    "========================================"
  );

  console.log(
    "❌ FOODJET - CANCELAR ORDER"
  );

  console.log(
    "🌎 AMBIENTE: PRODUÇÃO"
  );

  console.log(
    "🆔 ORDER ID:",
    orderId
  );

  console.log(
    "========================================"
  );

  const cancelUrl =
    `${API_URL}/${encodeURIComponent(orderId)}/cancel`;

  let resposta;

  try {
    resposta =
      await fetch(
        cancelUrl,
        {
          method: "POST",

          headers: {
            Authorization:
              `Bearer ${ACCESS_TOKEN}`,

            "Content-Type":
              "application/json",

            "X-Idempotency-Key":
              gerarIdempotencyKey(),
          },
        }
      );
  } catch (erro) {
    throw new Error(
      `Falha de conexão ao cancelar Order: ${erro.message}`
    );
  }

  const texto =
    await resposta.text();

  let dados;

  try {
    dados =
      texto
        ? JSON.parse(texto)
        : {};
  } catch {
    dados = {
      raw: texto,
    };
  }

  if (!resposta.ok) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO AO CANCELAR ORDER"
    );

    console.error(
      "STATUS:",
      resposta.status
    );

    console.error(
      JSON.stringify(
        dados,
        null,
        2
      )
    );

    console.error(
      "========================================"
    );

    const erro =
      new Error(
        dados?.message ||
        dados?.error ||
        "Erro ao cancelar Order"
      );

    erro.status =
      resposta.status;

    erro.response =
      dados;

    erro.causes =
      dados?.errors ||
      dados?.causes ||
      [];

    throw erro;
  }

  console.log(
    "========================================"
  );

  console.log(
    "✅ ORDER CANCELADA"
  );

  console.log(
    "🆔 ORDER ID:",
    dados.id ||
    orderId
  );

  console.log(
    "========================================"
  );

  return dados;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  criarPix,
  consultarOrder,
  cancelarOrder,
};

