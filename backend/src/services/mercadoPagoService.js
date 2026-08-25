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
 * - Criar Orders
 * - Consultar Orders
 * - Consultar pagamentos dentro da Order
 * - Trabalhar exclusivamente com Access Token
 *
 * ============================================================
 */

require("dotenv").config({
  override: true,
});

const {
  MercadoPagoConfig,
  Order,
} = require("mercadopago");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const ACCESS_TOKEN =
  String(
    process.env.MERCADOPAGO_ACCESS_TOKEN || ""
  ).trim();

const AMBIENTE =
  String(
    process.env.MERCADOPAGO_ENV || "production"
  ).trim();

const TIMEOUT =
  Number(
    process.env.MERCADOPAGO_TIMEOUT || 10000
  );

// ============================================================
// VALIDAÇÃO
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
// IDENTIFICAR TIPO DO TOKEN
// ============================================================

const tokenEhProducao =
  ACCESS_TOKEN.startsWith(
    "APP_USR-"
  );

const tokenEhTeste =
  ACCESS_TOKEN.startsWith(
    "TEST-"
  );

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
    accessToken:
      ACCESS_TOKEN,

    options: {
      timeout:
        TIMEOUT,
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

    // --------------------------------------------------------
    // REQUEST OPTIONS
    // --------------------------------------------------------

    const requestOptions = {};

    if (idempotencyKey) {
      requestOptions.idempotencyKey =
        String(
          idempotencyKey
        );
    }

    // --------------------------------------------------------
    // CRIAR
    // --------------------------------------------------------

    const resposta =
      await orderClient.create({
        body: dados,
        requestOptions,
      });

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

    // --------------------------------------------------------
    // GET /v1/orders/{order_id}
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // PAYMENT
    // --------------------------------------------------------

    const payment =
      resposta
        ?.transactions
        ?.payments
        ?.[0];

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
// EXTRAIR PAYMENT DA ORDER
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
// VERIFICAR PAGAMENTO APROVADO
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
// VERIFICAR PAGAMENTO PENDENTE
// ============================================================

function pagamentoPendente(
  order
) {
  return (
    order?.status ===
      "action_required"
  );
}

// ============================================================
// VERIFICAR PAGAMENTO FALHOU
// ============================================================

function pagamentoFalhou(
  order
) {
  return (
    order?.status ===
      "failed"
  );
}

// ============================================================
// VERIFICAR CANCELADO / EXPIRADO
// ============================================================

function pagamentoCancelado(
  order
) {
  return (
    order?.status ===
      "cancelled" ||
    order?.status ===
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
  criarOrder,

  consultarOrder,

  obterPayment,

  pagamentoAprovado,

  pagamentoPendente,

  pagamentoFalhou,

  pagamentoCancelado,

  obterResumoPagamento,

  mercadoPagoClient,

  orderClient,
};