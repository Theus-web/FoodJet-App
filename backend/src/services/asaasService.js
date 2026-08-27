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
  // NORMALIZAR CPF/CNPJ
  // ==========================================================

  const documento =
    cpfCnpj
      ? String(cpfCnpj)
          .replace(/\D/g, "")
      : "";

  // ==========================================================
  // PROCURAR CLIENTE PELO CPF/CNPJ
  // ==========================================================

  if (documento) {

    try {

      const busca =
        await api.get(
          "/v3/customers",
          {
            params: {
              cpfCnpj:
                documento,
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
        "⚠️ NÃO FOI POSSÍVEL LOCALIZAR CLIENTE:"
      );

      console.warn(
        erro?.response?.data ||
        erro?.message
      );
    }
  }

  // ==========================================================
  // VALIDAR CPF/CNPJ
  // ==========================================================

  if (!documento) {

    throw new Error(
      "CPF ou CNPJ do cliente é obrigatório para criar a cobrança PIX."
    );
  }

  // ==========================================================
  // CRIAR CLIENTE
  // ==========================================================

  try {

    const response =
      await api.post(
        "/v3/customers",
        {

          name:
            nome ||
            "Cliente FoodJet",

          email:
            String(email)
              .trim()
              .toLowerCase(),

          cpfCnpj:
            documento,

          notificationDisabled:
            true,

        }
      );

    console.log(
      "✅ CLIENTE ASAAS CRIADO:",
      response.data.id
    );

    return response.data;

  } catch (erro) {

    console.error(
      "❌ ERRO CRIANDO CLIENTE ASAAS:"
    );

    console.error(
      JSON.stringify(
        erro?.response?.data ||
        {},
        null,
        2
      )
    );

    throw erro;
  }
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

  console.log(
    "🪪 CPF/CNPJ:",
    cpfCnpj
      ? "INFORMADO"
      : "NÃO INFORMADO"
  );

  console.log("========================================");

  // ==========================================================
  // VALIDAR VALOR
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

  // ==========================================================
  // VALIDAR EMAIL
  // ==========================================================

  if (
    !email ||
    !String(email).trim()
  ) {

    throw new Error(
      "E-mail obrigatório."
    );
  }

  // ==========================================================
  // VALIDAR REFERÊNCIA
  // ==========================================================

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

  try {

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

  } catch (erro) {

    console.error(
      "❌ ERRO CRIANDO COBRANÇA ASAAS:"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
    );

    console.error(
      "DETALHES:",
      JSON.stringify(
        erro?.response?.data ||
        {},
        null,
        2
      )
    );

    throw erro;
  }
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

  // ==========================================================
  // VALIDAR ID
  // ==========================================================

  if (
    !pagamentoId ||
    !String(pagamentoId).trim()
  ) {

    throw new Error(
      "ID do pagamento obrigatório."
    );
  }

  const id =
    String(pagamentoId).trim();

  console.log(
    "🆔 PAYMENT ID:",
    id
  );

  const endpoint =
    `/v3/payments/${encodeURIComponent(
      id
    )}/pixQrCode`;

  console.log(
    "🌐 ENDPOINT:",
    endpoint
  );

  console.log("========================================");

  // ==========================================================
  // IMPORTANTE:
  // GET SEM BODY
  // ==========================================================

  try {

    const response =
      await api.request({

        method:
          "GET",

        url:
          endpoint,

        headers: {

          Accept:
            "application/json",

          access_token:
            ASAAS_API_KEY,

        },

        // Não enviar data/body aqui.
      });

    console.log("========================================");
    console.log("✅ QR CODE PIX OBTIDO");
    console.log("========================================");

    console.log(
      "🆔 PAYMENT ID:",
      id
    );

    console.log(
      "📱 PAYLOAD:",
      response.data?.payload
        ? "SIM"
        : "NÃO"
    );

    console.log(
      "🖼️ BASE64:",
      response.data?.encodedImage
        ? "SIM"
        : "NÃO"
    );

    console.log(
      "⏰ EXPIRAÇÃO:",
      response.data?.expirationDate ||
      ""
    );

    console.log("========================================");

    return response.data;

  } catch (erro) {

    console.error("========================================");
    console.error(
      "❌ ERRO AO OBTER QR CODE PIX ASAAS"
    );
    console.error("========================================");

    console.error(
      "🆔 PAYMENT ID:",
      id
    );

    console.error(
      "HTTP STATUS:",
      erro?.response?.status
    );

    console.error(
      "MENSAGEM:",
      erro?.message
    );

    console.error(
      "RESPOSTA ASAAS:"
    );

    console.error(
      JSON.stringify(
        erro?.response?.data ||
        {},
        null,
        2
      )
    );

    console.error("========================================");

    const detalhes =
      erro?.response?.data;

    let mensagemErro =
      "Erro ao obter QR Code PIX no Asaas.";

    if (
      detalhes?.errors &&
      Array.isArray(
        detalhes.errors
      )
    ) {

      mensagemErro =
        detalhes.errors
          .map(
            erroItem =>
              erroItem?.description ||
              erroItem?.message ||
              JSON.stringify(
                erroItem
              )
          )
          .join(" | ");

    } else if (
      detalhes?.message
    ) {

      mensagemErro =
        detalhes.message;

    } else if (
      typeof detalhes === "string"
    ) {

      mensagemErro =
        detalhes;
    }

    const novoErro =
      new Error(
        mensagemErro
      );

    novoErro.status =
      erro?.response?.status;

    novoErro.response =
      erro?.response;

    throw novoErro;
  }
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

  if (
    !pagamentoId ||
    !String(pagamentoId).trim()
  ) {

    throw new Error(
      "ID do pagamento obrigatório."
    );
  }

  const id =
    String(pagamentoId).trim();

  console.log(
    "🆔 PAYMENT ID:",
    id
  );

  try {

    const response =
      await api.request({

        method:
          "GET",

        url:
          `/v3/payments/${encodeURIComponent(
            id
          )}`,

        headers: {

          Accept:
            "application/json",

          access_token:
            ASAAS_API_KEY,

        },

      });

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

    return response.data;

  } catch (erro) {

    console.error(
      "❌ ERRO CONSULTANDO PAGAMENTO ASAAS:"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
    );

    console.error(
      "DETALHES:",
      JSON.stringify(
        erro?.response?.data ||
        {},
        null,
        2
      )
    );

    throw erro;
  }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

  criarPix,

  consultarPagamento,

  obterQrCodePix,

};