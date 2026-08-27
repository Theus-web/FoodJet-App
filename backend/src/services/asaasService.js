require("dotenv").config();

const axios = require("axios");

// ============================================================
// CONFIGURAÇÃO ASAAS
// ============================================================

const ASAAS_API_KEY =
  process.env.ASAAS_API_KEY;

const ASAAS_API_URL =
  process.env.ASAAS_API_URL ||
  "https://api.asaas.com";

console.log("========================================");
console.log("🔐 FOODJET - ASAAS SERVICE");
console.log("========================================");

console.log(
  "API KEY CARREGADA:",
  ASAAS_API_KEY ? "SIM" : "NÃO"
);

console.log(
  "AMBIENTE:",
  process.env.ASAAS_ENVIRONMENT ||
    "production"
);

console.log(
  "API:",
  ASAAS_API_URL
);

console.log("========================================");

// ============================================================
// VALIDAR API KEY
// ============================================================

if (!ASAAS_API_KEY) {

  console.error(
    "❌ ASAAS_API_KEY não configurada."
  );

  throw new Error(
    "ASAAS_API_KEY não configurada."
  );
}

// ============================================================
// CLIENTE ASAAS
// ============================================================

const api = axios.create({

  baseURL:
    ASAAS_API_URL,

  timeout:
    30000,

  headers: {

    "Content-Type":
      "application/json",

    Accept:
      "application/json",

    access_token:
      ASAAS_API_KEY,

  },

});

// ============================================================
// CRIAR CLIENTE
// ============================================================

async function criarCliente({
  nome,
  email,
  cpfCnpj,
}) {

  console.log(
    "👤 CRIANDO/LOCALIZANDO CLIENTE ASAAS"
  );

  // ==========================================================
  // TENTAR LOCALIZAR CLIENTE PELO CPF/CNPJ
  // ==========================================================

  if (cpfCnpj) {

    try {

      const busca =
        await api.get(
          "/v3/customers",
          {
            params: {
              cpfCnpj:
                String(cpfCnpj)
                  .replace(/\D/g, ""),
            },
          }
        );

      if (
        busca.data &&
        Array.isArray(
          busca.data.data
        ) &&
        busca.data.data.length > 0
      ) {

        const cliente =
          busca.data.data[0];

        console.log(
          "✅ CLIENTE JÁ EXISTE:",
          cliente.id
        );

        return cliente;
      }

    } catch (erro) {

      console.warn(
        "⚠️ Não foi possível localizar cliente:",
        erro?.message
      );

    }

  }

  // ==========================================================
  // CRIAR CLIENTE
  // ==========================================================

  const response =
    await api.post(
      "/v3/customers",
      {

        name:
          nome ||
          "Cliente FoodJet",

        email:
          email,

        cpfCnpj:
          cpfCnpj
            ? String(cpfCnpj)
                .replace(/\D/g, "")
            : undefined,

        notificationDisabled:
          true,

      }
    );

  console.log(
    "✅ CLIENTE ASAAS CRIADO:",
    response.data.id
  );

  return response.data;
}

// ============================================================
// CRIAR PIX
// ============================================================

async function criarPix({

  valor,

  email,

  referencia,

  descricao,

  nome,

  cpfCnpj,

}) {

  console.log("========================================");
  console.log("💳 ASAAS - CRIAR PIX");
  console.log("========================================");

  console.log(
    "💰 VALOR:",
    valor
  );

  console.log(
    "📧 EMAIL:",
    email
  );

  console.log(
    "🔖 REFERÊNCIA:",
    referencia
  );

  console.log("========================================");

  // ==========================================================
  // VALIDAR
  // ==========================================================

  if (
    !Number.isFinite(
      Number(valor)
    ) ||
    Number(valor) <= 0
  ) {

    throw new Error(
      "Valor inválido para pagamento."
    );

  }

  if (
    !email ||
    !String(email).trim()
  ) {

    throw new Error(
      "E-mail obrigatório."
    );

  }

  if (
    !referencia ||
    !String(referencia).trim()
  ) {

    throw new Error(
      "Referência obrigatória."
    );

  }

  // ==========================================================
  // CLIENTE
  // ==========================================================

  const cliente =
    await criarCliente({

      nome,

      email:
        String(email)
          .trim()
          .toLowerCase(),

      cpfCnpj,

    });

  // ==========================================================
  // DATA DE VENCIMENTO
  // ==========================================================

  const agora =
    new Date();

  const ano =
    agora.getFullYear();

  const mes =
    String(
      agora.getMonth() + 1
    ).padStart(2, "0");

  const dia =
    String(
      agora.getDate()
    ).padStart(2, "0");

  const dueDate =
    `${ano}-${mes}-${dia}`;

  // ==========================================================
  // CRIAR COBRANÇA
  // ==========================================================

  const response =
    await api.post(
      "/v3/payments",
      {

        customer:
          cliente.id,

        billingType:
          "PIX",

        value:
          Number(
            Number(valor).toFixed(2)
          ),

        dueDate,

        description:
          descricao ||
          `Pedido FoodJet #${referencia}`,

        externalReference:
          String(referencia),

        postalService:
          false,

      }
    );

  console.log("========================================");
  console.log("✅ COBRANÇA ASAAS CRIADA");
  console.log("========================================");

  console.log(
    "🆔 ID:",
    response.data?.id
  );

  console.log(
    "📊 STATUS:",
    response.data?.status
  );

  console.log(
    "💰 VALOR:",
    response.data?.value
  );

  console.log(
    "🔖 REFERÊNCIA:",
    response.data?.externalReference
  );

  console.log("========================================");

  return response.data;
}

// ============================================================
// OBTER QR CODE PIX
// ============================================================

async function obterQrCodePix(
  pagamentoId
) {

  console.log("========================================");
  console.log("📱 ASAAS - OBTER QR CODE PIX");
  console.log("========================================");

  console.log(
    "🆔 PAYMENT ID:",
    pagamentoId
  );

  if (
    !pagamentoId
  ) {

    throw new Error(
      "ID do pagamento obrigatório."
    );

  }

  const response =
    await api.get(
      `/v3/payments/${encodeURIComponent(
        pagamentoId
      )}/pixQrCode`
    );

  console.log(
    "✅ QR CODE PIX OBTIDO"
  );

  return response.data;
}

// ============================================================
// CONSULTAR PAGAMENTO
// ============================================================

async function consultarPagamento(
  pagamentoId
) {

  console.log("========================================");
  console.log("🔎 ASAAS - CONSULTAR PAGAMENTO");
  console.log("========================================");

  console.log(
    "🆔 PAYMENT ID:",
    pagamentoId
  );

  if (
    !pagamentoId
  ) {

    throw new Error(
      "ID do pagamento obrigatório."
    );

  }

  const response =
    await api.get(
      `/v3/payments/${encodeURIComponent(
        pagamentoId
      )}`
    );

  console.log(
    "📊 STATUS:",
    response.data?.status
  );

  return response.data;
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

  criarPix,

  consultarPagamento,

  obterQrCodePix,

};