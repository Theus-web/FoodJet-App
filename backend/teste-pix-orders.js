require("dotenv").config({ override: true });

const https = require("https");
const crypto = require("crypto");

const token = process.env.MERCADOPAGO_ACCESS_TOKEN?.trim();

console.log("========================================");
console.log("FOODJET - TESTE PIX ORDERS");
console.log("========================================");
console.log("TOKEN:", !!token);
console.log("PREFIXO:", token?.substring(0, 12));
console.log("TAMANHO:", token?.length);
console.log("========================================");

if (!token) {
  console.error("TOKEN NAO CARREGADO");
  process.exit(1);
}

const idempotencyKey = crypto.randomUUID();

const body = {
  type: "online",

  processing_mode: "automatic",

  total_amount: "10.00",

  external_reference: "TESTE-FOODJET-001",

  payer: {
    email: "test_user_4575768576989414454@testuser.com"
  },

  transactions: {
    payments: [
      {
        amount: "10.00",

        payment_method: {
          id: "pix",
          type: "bank_transfer"
        }
      }
    ]
  }
};

const bodyString = JSON.stringify(body);

const options = {
  hostname: "api.mercadopago.com",
  port: 443,
  path: "/v1/orders",
  method: "POST",

  headers: {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(bodyString),
    "X-Idempotency-Key": idempotencyKey,
  },
};

console.log("========================================");
console.log("TESTE ORDERS API");
console.log("========================================");
console.log("IDEMPOTENCY:", idempotencyKey);
console.log("VALOR: R$ 10,00");
console.log("========================================");

const req = https.request(options, (res) => {
  let resposta = "";

  res.on("data", (chunk) => {
    resposta += chunk;
  });

  res.on("end", () => {
    console.log("========================================");
    console.log("STATUS:", res.statusCode);
    console.log("========================================");

    try {
      const json = JSON.parse(resposta);

      console.log(JSON.stringify(json, null, 2));
    } catch {
      console.log(resposta);
    }

    console.log("========================================");
  });
});

req.on("error", (erro) => {
  console.error("========================================");
  console.error("ERRO DE CONEXAO");
  console.error("========================================");
  console.error(erro);
  console.error("========================================");
});

req.write(bodyString);

req.end();
