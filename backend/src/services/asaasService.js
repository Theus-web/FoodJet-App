require("dotenv").config();

const axios = require("axios");

// ============================================================
// CONFIGURAÇÃO ASAAS
// ============================================================

const ASAAS_API_KEY = process.env.ASAAS_API_KEY;

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
  process.env.ASAAS_ENVIRONMENT || "production"
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

  baseURL: ASAAS_API_URL,

  timeout: 30000,

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
// DATA
// ============================================================

function obterDataHoje() {

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

  return `${ano}-${mes}-${dia}`;
}

// ============================================================
// CRIAR / LOCALIZAR CLIENTE ASAAS
// ============================================================

async function criarCliente({

  nome,
  email,
  cpf,
  telefone,
  usuarioId,

}) {

  const documento =
    cpf
      ? String(cpf)
          .replace(/\D/g, "")
      : "";

  // ==========================================================
  // VALIDAR CPF
  // ==========================================================

  if (!documento) {

    throw new Error(
      "CPF não cadastrado. Atualize seu cadastro antes de realizar o pagamento."
    );
  }

  if (!nome) {

    throw new Error(
      "Nome do cliente não encontrado."
    );
  }

  if (!email) {

    throw new Error(
      "E-mail do cliente não encontrado."
    );
  }

  // ==========================================================
  // PROCURAR CLIENTE PELO CPF
  // ==========================================================

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
        "✅ CLIENTE ASAAS ENCONTRADO:",
        cliente.id
      );

      return cliente;
    }

  } catch (erro) {

    console.warn(
      "⚠️ NÃO FOI POSSÍVEL LOCALIZAR CLIENTE ASAAS PELO CPF:"
    );

    console.warn(
      erro?.response?.data ||
      erro?.message
    );
  }

  // ==========================================================
  // CRIAR CLIENTE ASAAS
  // ==========================================================

  const body = {

    name:
      String(nome).trim(),

    email:
      String(email)
        .trim()
        .toLowerCase(),

    cpfCnpj:
      documento,

    notificationDisabled:
      true,
  };

  if (telefone) {

    body.mobilePhone =
      String(telefone)
        .replace(/\D/g, "");
  }

  if (usuarioId) {

    body.externalReference =
      String(usuarioId);
  }

  try {

    const response =
      await api.post(
        "/v3/customers",
        body
      );

    console.log(
      "✅ CLIENTE ASAAS CRIADO:",
      response.data?.id
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
// CRIAR COBRANÇA - CARTÃO DE CRÉDITO
// ============================================================
//
// Fluxo:
//
// FoodJet
//    ↓
// Cliente ASAAS
//    ↓
// Cobrança CREDIT_CARD
//    ↓
// invoiceUrl
//    ↓
// Cliente informa cartão na página ASAAS
//
// ============================================================

async function criarCartao({

  valor,
  email,
  referencia,
  descricao,
  nome,
  cpf,
  telefone,
  usuarioId,

}) {

  const valorNumerico =
    Number(valor);

  // ==========================================================
  // VALOR
  // ==========================================================

  if (
    !Number.isFinite(
      valorNumerico
    ) ||
    valorNumerico <= 0
  ) {

    throw new Error(
      "Valor inválido para pagamento."
    );
  }

  // ==========================================================
  // EMAIL
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
  // REFERÊNCIA
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

      cpf,

      telefone,

      usuarioId,
    });

  // ==========================================================
  // COBRANÇA
  // ==========================================================

  const body = {

    customer:
      cliente.id,

    billingType:
      "CREDIT_CARD",

    value:
      Number(
        valorNumerico.toFixed(2)
      ),

    dueDate:
      obterDataHoje(),

    description:
      descricao ||
      `Pedido FoodJet #${referencia}`,

    externalReference:
      String(referencia),

    postalService:
      false,
  };

  try {

    const response =
      await api.post(
        "/v3/payments",
        body
      );

    console.log(
      "========================================"
    );

    console.log(
      "💳 FOODJET - CARTÃO DE CRÉDITO"
    );

    console.log(
      "CLIENTE ASAAS:",
      cliente.id
    );

    console.log(
      "PAGAMENTO:",
      response.data?.id
    );

    console.log(
      "PEDIDO:",
      referencia
    );

    console.log(
      "VALOR:",
      response.data?.value
    );

    console.log(
      "STATUS:",
      response.data?.status
    );

    console.log(
      "INVOICE URL:",
      response.data?.invoiceUrl ||
      "NÃO INFORMADA"
    );

    console.log(
      "========================================"
    );

    return response.data;

  } catch (erro) {

    console.error(
      "❌ ERRO CRIANDO COBRANÇA CARTÃO ASAAS:"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
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
// CRIAR COBRANÇA - CARTÃO DE DÉBITO
// ============================================================
//
// ATENÇÃO:
//
// O Asaas NÃO permite enviar número, validade e CVV
// de cartão de débito diretamente pela API.
//
// Para débito:
// 1. Criamos a cobrança no Asaas
// 2. Usamos billingType CREDIT_CARD
// 3. Pegamos a invoiceUrl
// 4. O cliente abre a página do Asaas
// 5. Na página da fatura ele poderá escolher DÉBITO
//
// ============================================================

async function criarDebito({
  valor,
  email,
  referencia,
  descricao,
  nome,
  cpf,
  telefone,
  usuarioId,
}) {

  // ==========================================================
  // VALOR
  // ==========================================================

  const valorNumerico =
    Number(valor);

  if (
    !Number.isFinite(valorNumerico) ||
    valorNumerico <= 0
  ) {
    throw new Error(
      "Valor inválido para pagamento."
    );
  }

  // ==========================================================
  // EMAIL
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
  // REFERÊNCIA
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
  // CLIENTE ASAAS
  // ==========================================================

  const cliente =
    await criarCliente({
      nome,
      email:
        String(email)
          .trim()
          .toLowerCase(),

      cpf,

      telefone,

      usuarioId,
    });

  // ==========================================================
  // COBRANÇA
  // ==========================================================

  const body = {

    customer:
      cliente.id,

    // O Asaas usa CREDIT_CARD para disponibilizar
    // o pagamento por cartão através da invoiceUrl.
    billingType:
      "CREDIT_CARD",

    value:
      Number(
        valorNumerico.toFixed(2)
      ),

    dueDate:
      obterDataHoje(),

    description:
      descricao ||
      `Pedido FoodJet #${referencia}`,

    externalReference:
      String(referencia),

    postalService:
      false,
  };

  try {

    console.log("");
    console.log(
      "========================================"
    );

    console.log(
      "💳 FOODJET - CRIANDO COBRANÇA DÉBITO"
    );

    console.log(
      "CLIENTE:",
      cliente.id
    );

    console.log(
      "VALOR:",
      body.value
    );

    console.log(
      "REFERÊNCIA:",
      referencia
    );

    console.log(
      "BILLING TYPE:",
      body.billingType
    );

    console.log(
      "========================================"
    );

    const response =
      await api.post(
        "/v3/payments",
        body
      );

    console.log("");
    console.log(
      "========================================"
    );

    console.log(
      "✅ COBRANÇA DÉBITO CRIADA"
    );

    console.log(
      "PAGAMENTO:",
      response.data?.id
    );

    console.log(
      "STATUS:",
      response.data?.status
    );

    console.log(
      "INVOICE URL:",
      response.data?.invoiceUrl ||
        "NÃO INFORMADA"
    );

    console.log(
      "========================================"
    );

    // ========================================================
    // VALIDAR INVOICE URL
    // ========================================================

    if (
      !response.data?.invoiceUrl
    ) {
      throw new Error(
        "O Asaas criou a cobrança, mas não retornou a invoiceUrl."
      );
    }

    return response.data;

  } catch (erro) {

    console.error("");
    console.error(
      "❌ ERRO CRIANDO COBRANÇA DÉBITO ASAAS"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
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
  cpf,
  telefone,
  usuarioId,

}) {

  const valorNumerico =
    Number(valor);

  // ==========================================================
  // VALOR
  // ==========================================================

  if (
    !Number.isFinite(
      valorNumerico
    ) ||
    valorNumerico <= 0
  ) {

    throw new Error(
      "Valor inválido para pagamento."
    );
  }

  // ==========================================================
  // EMAIL
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
  // REFERÊNCIA
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
  // CLIENTE ASAAS
  // ==========================================================

  const cliente =
    await criarCliente({

      nome,

      email:
        String(email)
          .trim()
          .toLowerCase(),

      cpf,

      telefone,

      usuarioId,
    });

  // ==========================================================
  // COBRANÇA PIX
  // ==========================================================

  const body = {

    customer:
      cliente.id,

    billingType:
      "PIX",

    value:
      Number(
        valorNumerico.toFixed(2)
      ),

    dueDate:
      obterDataHoje(),

    description:
      descricao ||
      `Pedido FoodJet #${referencia}`,

    externalReference:
      String(referencia),

    postalService:
      false,
  };

  try {

    const response =
      await api.post(
        "/v3/payments",
        body
      );

    console.log(
      "========================================"
    );

    console.log(
      "💰 FOODJET - PIX CRIADO"
    );

    console.log(
      "CLIENTE ASAAS:",
      cliente.id
    );

    console.log(
      "PAGAMENTO:",
      response.data?.id
    );

    console.log(
      "PEDIDO:",
      referencia
    );

    console.log(
      "VALOR:",
      response.data?.value
    );

    console.log(
      "STATUS:",
      response.data?.status
    );

    console.log(
      "========================================"
    );

    return response.data;

  } catch (erro) {

    console.error(
      "❌ ERRO CRIANDO PIX ASAAS:"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
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
// QR CODE PIX
// ============================================================

async function obterQrCodePix(
  pagamentoId
) {

  if (
    !pagamentoId ||
    !String(pagamentoId).trim()
  ) {

    throw new Error(
      "ID do pagamento obrigatório."
    );
  }

  const id =
    String(
      pagamentoId
    ).trim();

  try {

    const response =
      await api.get(
        `/v3/payments/${encodeURIComponent(
          id
        )}/pixQrCode`
      );

    return response.data;

  } catch (erro) {

    console.error(
      "❌ ERRO OBTENDO QR CODE PIX:"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
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
// CONSULTAR PAGAMENTO
// ============================================================

async function consultarPagamento(
  pagamentoId
) {

  if (
    !pagamentoId ||
    !String(pagamentoId).trim()
  ) {

    throw new Error(
      "ID do pagamento obrigatório."
    );
  }

  const id =
    String(
      pagamentoId
    ).trim();

  try {

    const response =
      await api.get(
        `/v3/payments/${encodeURIComponent(
          id
        )}`
      );

    return response.data;

  } catch (erro) {

    console.error(
      "❌ ERRO CONSULTANDO PAGAMENTO:"
    );

    console.error(
      "STATUS:",
      erro?.response?.status
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
// EXPORTAR
// ============================================================

module.exports = {

  criarPix,

  criarCartao,

  criarDebito,

  obterQrCodePix,

  consultarPagamento,

};