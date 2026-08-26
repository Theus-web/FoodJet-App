/**
 * ============================================================
 * FOODJET - MERCADO PAGO SERVICE
 * ============================================================
 *
 * PRODUÇÃO
 *
 * Responsável por:
 *
 * - Inicializar Mercado Pago
 * - Criar Orders PIX
 * - Consultar Orders
 * - Extrair dados do PIX
 * - Consultar pagamentos
 * - Retornar QR Code / Pix Copia e Cola / Ticket URL
 *
 * ============================================================
 */

require("dotenv").config();

const {
  MercadoPagoConfig,
  Order,
} = require("mercadopago");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const ACCESS_TOKEN = String(
  process.env.MERCADOPAGO_ACCESS_TOKEN || ""
).trim();

const AMBIENTE = String(
  process.env.MERCADOPAGO_ENV || "production"
).trim();

const TIMEOUT = Number(
  process.env.MERCADOPAGO_TIMEOUT || 10000
);

// ============================================================
// VALIDAÇÃO DO TOKEN
// ============================================================

if (!ACCESS_TOKEN) {
  console.error(
    "========================================"
  );

  console.error(
    "❌ MERCADOPAGO_ACCESS_TOKEN NÃO CONFIGURADO"
  );

  console.error(
    "========================================"
  );

  throw new Error(
    "MERCADOPAGO_ACCESS_TOKEN não configurado."
  );
}

// ============================================================
// IDENTIFICAR TOKEN
// ============================================================

const tokenEhProducao =
  ACCESS_TOKEN.startsWith("APP_USR-");

const tokenEhTeste =
  ACCESS_TOKEN.startsWith("TEST-");

// ============================================================
// LOG INICIAL
// ============================================================

console.log(
  "========================================"
);

console.log(
  "🔐 MERCADO PAGO - FOODJET"
);

console.log(
  "========================================"
);

console.log(
  "TOKEN CARREGADO: SIM"
);

console.log(
  "AMBIENTE:",
  AMBIENTE
);

if (tokenEhProducao) {
  console.log(
    "TIPO DO TOKEN: ✅ PRODUÇÃO"
  );
} else if (tokenEhTeste) {
  console.log(
    "TIPO DO TOKEN: ⚠️ TESTE"
  );
} else {
  console.log(
    "TIPO DO TOKEN: ⚠️ DESCONHECIDO"
  );
}

console.log(
  "API: https://api.mercadopago.com/v1/orders"
);

console.log(
  "========================================"
);

// ============================================================
// CLIENTE MERCADO PAGO
// ============================================================

const mercadoPagoClient =
  new MercadoPagoConfig({
    accessToken: ACCESS_TOKEN,

    options: {
      timeout: TIMEOUT,
    },
  });

// ============================================================
// CLIENTE ORDERS
// ============================================================

const orderClient =
  new Order(
    mercadoPagoClient
  );

// ============================================================
// CRIAR ORDER
// ============================================================

async function criarOrder(
  dados,
  idempotencyKey = null
) {
  try {
    if (!dados) {
      throw new Error(
        "Dados da Order não informados."
      );
    }

    console.log(
      "========================================"
    );

    console.log(
      "💳 MERCADO PAGO - CRIAR ORDER"
    );

    console.log(
      "========================================"
    );

    console.log(
      "💰 TOTAL:",
      dados.total_amount
    );

    console.log(
      "🔗 EXTERNAL REFERENCE:",
      dados.external_reference
    );

    console.log(
      "📦 TIPO:",
      dados.type
    );

    console.log(
      "========================================"
    );

    // ========================================================
    // IDEMPOTENCY KEY
    // ========================================================

    const requestOptions = {};

    if (idempotencyKey) {
      requestOptions.idempotencyKey =
        String(idempotencyKey);
    }

    // ========================================================
    // CRIAR ORDER
    // ========================================================

    const resposta =
      await orderClient.create({
        body: dados,
        requestOptions,
      });

    if (!resposta) {
      throw new Error(
        "Mercado Pago não retornou a Order."
      );
    }

    console.log(
      "========================================"
    );

    console.log(
      "✅ ORDER CRIADA"
    );

    console.log(
      "🆔 ORDER ID:",
      resposta?.id
    );

    console.log(
      "📊 STATUS:",
      resposta?.status
    );

    console.log(
      "📋 STATUS DETAIL:",
      resposta?.status_detail
    );

    console.log(
      "🔗 EXTERNAL REFERENCE:",
      resposta?.external_reference
    );

    // ========================================================
    // PAYMENT
    // ========================================================

    const payment =
      obterPayment(
        resposta
      );

    if (payment) {
      console.log(
        "----------------------------------------"
      );

      console.log(
        "💳 PAYMENT"
      );

      console.log(
        "🆔 PAYMENT ID:",
        payment?.id
      );

      console.log(
        "📊 PAYMENT STATUS:",
        payment?.status
      );

      console.log(
        "📋 PAYMENT DETAIL:",
        payment?.status_detail
      );

      console.log(
        "💰 AMOUNT:",
        payment?.amount
      );

      console.log(
        "----------------------------------------"
      );

      const pix =
        obterDadosPix(
          resposta
        );

      console.log(
        "🔑 PIX COPIA E COLA:",
        pix.qrCode
          ? "SIM"
          : "NÃO"
      );

      console.log(
        "🖼️ QR CODE BASE64:",
        pix.qrCodeBase64
          ? "SIM"
          : "NÃO"
      );

      console.log(
        "🔗 TICKET URL:",
        pix.ticketUrl
          ? "SIM"
          : "NÃO"
      );
    }

    console.log(
      "========================================"
    );

    return resposta;

  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO AO CRIAR ORDER MERCADO PAGO"
    );

    console.error(
      "MENSAGEM:",
      erro?.message
    );

    console.error(
      "STATUS:",
      erro?.status ||
      erro?.response?.status
    );

    console.error(
      "DETALHES:",
      erro?.response?.data ||
      erro?.cause ||
      ""
    );

    console.error(
      "========================================"
    );

    throw erro;
  }
}

// ============================================================
// CRIAR PIX
// ============================================================
//
// Compatibilidade com seu controller/rota:
//
// const { criarPix } = require(...)
//
// ============================================================

async function criarPix({
  valor,
  email,
  referencia,
  idempotencyKey = null,
  descricao = null,
}) {
  try {
    if (!valor) {
      throw new Error(
        "Valor do PIX não informado."
      );
    }

    if (!email) {
      throw new Error(
        "Email do pagador não informado."
      );
    }

    if (!referencia) {
      throw new Error(
        "Referência do PIX não informada."
      );
    }

    const valorNumerico =
      Number(valor);

    if (
      !Number.isFinite(
        valorNumerico
      ) ||
      valorNumerico <= 0
    ) {
      throw new Error(
        "Valor do PIX inválido."
      );
    }

    const total =
      valorNumerico.toFixed(2);

    console.log(
      "========================================"
    );

    console.log(
      "💳 FOODJET - CRIAR PIX"
    );

    console.log(
      "========================================"
    );

    console.log(
      "💰 VALOR:",
      valorNumerico
    );

    console.log(
      "📧 EMAIL:",
      email
    );

    console.log(
      "🔖 REFERÊNCIA:",
      referencia
    );

    console.log(
      "----------------------------------------"
    );

    // ========================================================
    // PAYLOAD PIX
    // ========================================================

    const dados = {
      type: "online",

      processing_mode:
        "automatic",

      total_amount:
        total,

      external_reference:
        String(referencia),

      description:
        descricao ||
        `Pedido FoodJet #${referencia}`,

      transactions: {
        payments: [
          {
            amount:
              total,

            payment_method: {
              id: "pix",
              type: "bank_transfer",
            },
          },
        ],
      },

      payer: {
        email:
          String(email).trim(),
      },
    };

    console.log(
      "📦 CRIANDO ORDER PIX"
    );

    console.log(
      "PAYLOAD:",
      JSON.stringify(
        dados,
        null,
        2
      )
    );

    console.log(
      "----------------------------------------"
    );

    // ========================================================
    // IDEMPOTÊNCIA
    // ========================================================

    const chave =
      idempotencyKey ||
      `foodjet-pix-${referencia}`;

    // ========================================================
    // CRIAR ORDER
    // ========================================================

    const order =
      await criarOrder(
        dados,
        chave
      );

    if (!order) {
      throw new Error(
        "Mercado Pago não retornou a Order PIX."
      );
    }

    // ========================================================
    // PAYMENT
    // ========================================================

    const payment =
      obterPayment(
        order
      );

    // ========================================================
    // DADOS PIX
    // ========================================================

    const pix =
      obterDadosPix(
        order
      );

    console.log(
      "========================================"
    );

    console.log(
      "✅ PIX CRIADO"
    );

    console.log(
      "========================================"
    );

    console.log(
      "🆔 ORDER ID:",
      order?.id
    );

    console.log(
      "🆔 PAYMENT ID:",
      payment?.id || ""
    );

    console.log(
      "📊 ORDER STATUS:",
      order?.status
    );

    console.log(
      "📋 ORDER STATUS DETAIL:",
      order?.status_detail
    );

    console.log(
      "📊 PAYMENT STATUS:",
      payment?.status
    );

    console.log(
      "📋 PAYMENT STATUS DETAIL:",
      payment?.status_detail
    );

    console.log(
      "💰 PAYMENT AMOUNT:",
      payment?.amount
    );

    console.log(
      "========================================"
    );

    console.log(
      "📲 DADOS PIX"
    );

    console.log(
      "🔑 QR CODE:",
      pix.qrCode
        ? "SIM"
        : "NÃO"
    );

    console.log(
      "🖼️ QR CODE BASE64:",
      pix.qrCodeBase64
        ? "SIM"
        : "NÃO"
    );

    console.log(
      "🔗 TICKET URL:",
      pix.ticketUrl
        ? "SIM"
        : "NÃO"
    );

    console.log(
      "========================================"
    );

    // ========================================================
    // RETORNO COMPATÍVEL COM O FRONTEND
    // ========================================================

    return {
      sucesso: true,

      id: order?.id || null,

      orderId:
        order?.id || null,

      paymentId:
        payment?.id || null,

      status:
        order?.status || null,

      statusDetail:
        order?.status_detail || null,

      paymentStatus:
        payment?.status || null,

      paymentStatusDetail:
        payment?.status_detail || null,

      externalReference:
        order?.external_reference ||
        referencia,

      valor:
        payment?.amount ||
        order?.total_amount ||
        total,

      // ======================================================
      // PIX
      // ======================================================

      qr_code:
        pix.qrCode,

      qrCode:
        pix.qrCode,

      qr_code_base64:
        pix.qrCodeBase64,

      qrCodeBase64:
        pix.qrCodeBase64,

      ticket_url:
        pix.ticketUrl,

      ticketUrl:
        pix.ticketUrl,

      // ======================================================
      // OBJETOS COMPLETOS
      // ======================================================

      order,

      payment,

      paymentMethod:
        payment?.payment_method ||
        null,
    };

  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO AO CRIAR PIX"
    );

    console.error(
      "MENSAGEM:",
      erro?.message
    );

    console.error(
      "STATUS:",
      erro?.status ||
      erro?.response?.status
    );

    console.error(
      "DETALHES:",
      erro?.response?.data ||
      erro?.cause ||
      ""
    );

    console.error(
      "========================================"
    );

    throw erro;
  }
}

// ============================================================
// CONSULTAR ORDER
// ============================================================

async function consultarOrder(
  orderId
) {
  try {
    if (!orderId) {
      throw new Error(
        "Order ID não informado."
      );
    }

    const id =
      String(
        orderId
      ).trim();

    console.log(
      "========================================"
    );

    console.log(
      "🔎 MERCADO PAGO - CONSULTAR ORDER"
    );

    console.log(
      "========================================"
    );

    console.log(
      "🆔 ORDER ID:",
      id
    );

    const resposta =
      await orderClient.get({
        id,
      });

    if (!resposta) {
      throw new Error(
        "Mercado Pago não retornou dados da Order."
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
      resposta?.id
    );

    console.log(
      "📊 STATUS:",
      resposta?.status
    );

    console.log(
      "📋 STATUS DETAIL:",
      resposta?.status_detail
    );

    console.log(
      "🔗 EXTERNAL REFERENCE:",
      resposta?.external_reference
    );

    // ========================================================
    // PAYMENT
    // ========================================================

    const payment =
      obterPayment(
        resposta
      );

    if (payment) {
      console.log(
        "----------------------------------------"
      );

      console.log(
        "💳 PAYMENT"
      );

      console.log(
        "🆔 PAYMENT ID:",
        payment?.id
      );

      console.log(
        "📊 PAYMENT STATUS:",
        payment?.status
      );

      console.log(
        "📋 PAYMENT DETAIL:",
        payment?.status_detail
      );

      console.log(
        "💰 PAYMENT AMOUNT:",
        payment?.amount
      );

      // ======================================================
      // PIX
      // ======================================================

      const pix =
        obterDadosPix(
          resposta
        );

      console.log(
        "🔑 QR CODE:",
        pix.qrCode
          ? "SIM"
          : "NÃO"
      );

      console.log(
        "🖼️ QR CODE BASE64:",
        pix.qrCodeBase64
          ? "SIM"
          : "NÃO"
      );

      console.log(
        "🔗 TICKET URL:",
        pix.ticketUrl
          ? "SIM"
          : "NÃO"
      );
    }

    console.log(
      "========================================"
    );

    return resposta;

  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO AO CONSULTAR ORDER"
    );

    console.error(
      "🆔 ORDER ID:",
      orderId
    );

    console.error(
      "MENSAGEM:",
      erro?.message
    );

    console.error(
      "STATUS:",
      erro?.status ||
      erro?.response?.status
    );

    console.error(
      "DETALHES:",
      erro?.response?.data ||
      erro?.cause ||
      ""
    );

    console.error(
      "========================================"
    );

    throw erro;
  }
}

// ============================================================
// OBTER PAYMENT
// ============================================================

function obterPayment(
  order
) {
  return (
    order
      ?.transactions
      ?.payments
      ?.[0] ||
    null
  );
}

// ============================================================
// OBTER PAYMENT METHOD
// ============================================================

function obterPaymentMethod(
  order
) {
  const payment =
    obterPayment(
      order
    );

  return (
    payment
      ?.payment_method ||
    null
  );
}

// ============================================================
// OBTER DADOS PIX
// ============================================================
//
// IMPORTANTE:
//
// Os dados estão aqui:
//
// transactions
//   └── payments[0]
//         └── payment_method
//               ├── qr_code
//               ├── qr_code_base64
//               └── ticket_url
//
// ============================================================

function obterDadosPix(
  order
) {
  const paymentMethod =
    obterPaymentMethod(
      order
    );

  return {
    qrCode:
      paymentMethod
        ?.qr_code ||
      null,

    qrCodeBase64:
      paymentMethod
        ?.qr_code_base64 ||
      null,

    ticketUrl:
      paymentMethod
        ?.ticket_url ||
      null,
  };
}

// ============================================================
// PAGAMENTO APROVADO
// ============================================================

function pagamentoAprovado(
  order
) {
  const payment =
    obterPayment(
      order
    );

  return (
    order?.status ===
      "processed" &&
    payment?.status ===
      "processed" &&
    payment?.status_detail ===
      "accredited"
  );
}

// ============================================================
// PAGAMENTO PENDENTE
// ============================================================

function pagamentoPendente(
  order
) {
  const payment =
    obterPayment(
      order
    );

  return (
    order?.status ===
      "action_required" ||
    payment?.status ===
      "action_required"
  );
}

// ============================================================
// PAGAMENTO FALHOU
// ============================================================

function pagamentoFalhou(
  order
) {
  const payment =
    obterPayment(
      order
    );

  return (
    order?.status ===
      "failed" ||
    payment?.status ===
      "failed"
  );
}

// ============================================================
// CANCELADO / EXPIRADO
// ============================================================

function pagamentoCancelado(
  order
) {
  const payment =
    obterPayment(
      order
    );

  return (
    order?.status ===
      "cancelled" ||
    order?.status ===
      "expired" ||
    payment?.status ===
      "cancelled" ||
    payment?.status ===
      "expired"
  );
}

// ============================================================
// RESUMO DO PAGAMENTO
// ============================================================

function obterResumoPagamento(
  order
) {
  const payment =
    obterPayment(
      order
    );

  const pix =
    obterDadosPix(
      order
    );

  return {
    orderId:
      order?.id ||
      null,

    orderStatus:
      order?.status ||
      null,

    orderStatusDetail:
      order?.status_detail ||
      null,

    externalReference:
      order?.external_reference ||
      null,

    paymentId:
      payment?.id ||
      null,

    paymentStatus:
      payment?.status ||
      null,

    paymentStatusDetail:
      payment?.status_detail ||
      null,

    paymentAmount:
      payment?.amount ||
      null,

    // ========================================================
    // PIX
    // ========================================================

    qrCode:
      pix.qrCode,

    qrCodeBase64:
      pix.qrCodeBase64,

    ticketUrl:
      pix.ticketUrl,

    // ========================================================
    // STATUS
    // ========================================================

    aprovado:
      pagamentoAprovado(
        order
      ),

    pendente:
      pagamentoPendente(
        order
      ),

    falhou:
      pagamentoFalhou(
        order
      ),

    cancelado:
      pagamentoCancelado(
        order
      ),
  };
}

// ============================================================
// EXPORTAÇÃO
// ============================================================

module.exports = {
  // ==========================================================
  // PRINCIPAIS
  // ==========================================================

  criarPix,

  criarOrder,

  consultarOrder,

  // ==========================================================
  // EXTRAÇÃO
  // ==========================================================

  obterPayment,

  obterPaymentMethod,

  obterDadosPix,

  obterResumoPagamento,

  // ==========================================================
  // STATUS
  // ==========================================================

  pagamentoAprovado,

  pagamentoPendente,

  pagamentoFalhou,

  pagamentoCancelado,

  // ==========================================================
  // CLIENTES
  // ==========================================================

  mercadoPagoClient,

  orderClient,
};