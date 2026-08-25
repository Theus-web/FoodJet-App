require("dotenv").config({ override: true });

const https = require("https");
const crypto = require("crypto");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const token =
  process.env.MERCADOPAGO_ACCESS_TOKEN?.trim();

const email =
  "fumanci2@gmail.com";

const valor =
  "1.00";

const referencia =
  `FOODJET-PROD-${Date.now()}`;

const idempotencyKey =
  crypto.randomUUID();

// ============================================================
// CABEÇALHO
// ============================================================

console.log("========================================");
console.log("💰 FOODJET - TESTE PIX PRODUÇÃO");
console.log("========================================");

console.log(
  "TOKEN:",
  token ? "CARREGADO" : "NÃO CARREGADO"
);

console.log(
  "PREFIXO:",
  token?.substring(0, 12) || "N/A"
);

console.log(
  "TAMANHO:",
  token?.length || 0
);

console.log(
  "AMBIENTE:",
  process.env.MERCADOPAGO_ENVIRONMENT ||
    "NÃO CONFIGURADO"
);

console.log(
  "TIPO:",
  token?.startsWith("APP_USR-")
    ? "✅ PRODUÇÃO"
    : token?.startsWith("TEST-")
      ? "❌ TESTE"
      : "⚠️ DESCONHECIDO"
);

console.log("========================================");

// ============================================================
// VALIDAÇÃO DO TOKEN
// ============================================================

if (!token) {
  console.error(
    "❌ MERCADOPAGO_ACCESS_TOKEN NÃO CARREGADO."
  );

  process.exit(1);
}

if (!token.startsWith("APP_USR-")) {
  console.error(
    "❌ O TOKEN NÃO É DE PRODUÇÃO."
  );

  console.error(
    "O token precisa começar com APP_USR-"
  );

  process.exit(1);
}

// ============================================================
// PAYLOAD
// ============================================================

const body = {

  type:
    "online",

  processing_mode:
    "automatic",

  total_amount:
    valor,

  external_reference:
    referencia,

  payer: {

    email:
      email,

  },

  transactions: {

    payments: [

      {

        amount:
          valor,

        payment_method: {

          id:
            "pix",

          type:
            "bank_transfer",

        },

      },

    ],

  },

};

// ============================================================
// JSON
// ============================================================

const bodyString =
  JSON.stringify(body);

// ============================================================
// REQUEST
// ============================================================

const options = {

  hostname:
    "api.mercadopago.com",

  port:
    443,

  path:
    "/v1/orders",

  method:
    "POST",

  headers: {

    Authorization:
      `Bearer ${token}`,

    "Content-Type":
      "application/json",

    "Content-Length":
      Buffer.byteLength(bodyString),

    "X-Idempotency-Key":
      idempotencyKey,

  },

};

// ============================================================
// INFORMAÇÕES DO TESTE
// ============================================================

console.log(
  "💳 CRIANDO PIX REAL"
);

console.log(
  "========================================"
);

console.log(
  "💰 VALOR: R$",
  valor
);

console.log(
  "📧 PAGADOR:",
  email
);

console.log(
  "📦 REFERÊNCIA:",
  referencia
);

console.log(
  "🔑 IDEMPOTENCY:",
  idempotencyKey
);

console.log(
  "🌐 API:",
  "https://api.mercadopago.com/v1/orders"
);

console.log(
  "========================================"
);

// ============================================================
// REQUISIÇÃO
// ============================================================

const req =
  https.request(
    options,
    (res) => {

      let resposta =
        "";

      res.on(
        "data",
        (chunk) => {

          resposta +=
            chunk;

        }
      );

      res.on(
        "end",
        () => {

          console.log(
            "========================================"
          );

          console.log(
            "📡 RESPOSTA MERCADO PAGO"
          );

          console.log(
            "STATUS HTTP:",
            res.statusCode
          );

          console.log(
            "========================================"
          );

          let dados;

          try {

            dados =
              JSON.parse(
                resposta
              );

          } catch {

            console.error(
              "❌ RESPOSTA NÃO É JSON:"
            );

            console.log(
              resposta
            );

            return;

          }

          // ==================================================
          // ERRO
          // ==================================================

          if (
            res.statusCode < 200 ||
            res.statusCode >= 300
          ) {

            console.error(
              "❌ ERRO AO CRIAR PIX"
            );

            console.error(
              "========================================"
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

            return;

          }

          // ==================================================
          // ORDER
          // ==================================================

          console.log(
            "✅ PIX CRIADO EM PRODUÇÃO"
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
            "📋 ORDER STATUS DETAIL:",
            dados.status_detail
          );

          console.log(
            "📦 REFERÊNCIA:",
            dados.external_reference
          );

          console.log(
            "💰 VALOR:",
            dados.total_amount
          );

          console.log(
            "💵 TOTAL PAGO:",
            dados.total_paid_amount
          );

          console.log(
            "💱 MOEDA:",
            dados.currency
          );

          // ==================================================
          // PAYMENT
          // ==================================================

          const payment =
            dados
              ?.transactions
              ?.payments
              ?.[0];

          if (!payment) {

            console.error(
              "❌ PAGAMENTO NÃO RETORNADO."
            );

            console.log(
              JSON.stringify(
                dados,
                null,
                2
              )
            );

            return;

          }

          console.log(
            "========================================"
          );

          console.log(
            "💳 PAGAMENTO"
          );

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
            "💰 PAYMENT AMOUNT:",
            payment.amount
          );

          // ==================================================
          // PAYMENT METHOD
          // ==================================================

          const paymentMethod =
            payment.payment_method ||
            {};

          // ==================================================
          // PIX
          // ==================================================

          const qrCode =
            paymentMethod.qr_code ||
            null;

          const qrCodeBase64 =
            paymentMethod.qr_code_base64 ||
            null;

          const ticketUrl =
            paymentMethod.ticket_url ||
            null;

          console.log(
            "========================================"
          );

          console.log(
            "📲 DADOS PIX"
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
            ticketUrl ||
              "NÃO INFORMADO"
          );

          console.log(
            "⏰ EXPIRAÇÃO:",
            payment.date_of_expiration ||
              "NÃO INFORMADA"
          );

          // ==================================================
          // PIX COPIA E COLA
          // ==================================================

          if (qrCode) {

            console.log(
              "========================================"
            );

            console.log(
              "📋 PIX COPIA E COLA"
            );

            console.log(
              "========================================"
            );

            console.log(
              qrCode
            );

            console.log(
              "========================================"
            );

          }

          // ==================================================
          // ORDER COMPLETA
          // ==================================================

          console.log(
            "📦 ORDER COMPLETA:"
          );

          console.log(
            JSON.stringify(
              dados,
              null,
              2
            )
          );

          console.log(
            "========================================"
          );

          console.log(
            "✅ FIM DO TESTE"
          );

          console.log(
            "========================================"
          );

        }
      );

    }
  );

// ============================================================
// ERRO DE CONEXÃO
// ============================================================

req.on(
  "error",
  (erro) => {

    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO DE CONEXÃO COM MERCADO PAGO"
    );

    console.error(
      erro.message
    );

    console.error(
      "========================================"
    );

  }
);

// ============================================================
// ENVIAR REQUEST
// ============================================================

req.write(
  bodyString
);

req.end();