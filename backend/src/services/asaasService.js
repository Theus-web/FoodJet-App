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
    "Content-Type": "application/json",
    Accept: "application/json",
    access_token: ASAAS_API_KEY,
  },
});

// ============================================================
// DATA
// ============================================================

function obterDataHoje() {
  const agora = new Date();

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
// LIMPAR TELEFONE
// ============================================================

function limparTelefone(valor) {
  return String(valor || "")
    .replace(/\D/g, "")
    .trim();
}

// ============================================================
// LIMPAR CEP
// ============================================================

function limparCep(valor) {
  return String(valor || "")
    .replace(/\D/g, "")
    .trim();
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

  const telefoneLimpo =
    limparTelefone(telefone);

  // ==========================================================
  // VALIDAR CPF
  // ==========================================================

  if (!documento) {
    throw new Error(
      "CPF não cadastrado. Atualize seu cadastro antes de realizar o pagamento."
    );
  }

  // ==========================================================
  // VALIDAR NOME
  // ==========================================================

  if (!nome || !String(nome).trim()) {
    throw new Error(
      "Nome do cliente não encontrado."
    );
  }

  // ==========================================================
  // VALIDAR EMAIL
  // ==========================================================

  if (!email || !String(email).trim()) {
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
      "⚠️ NÃO FOI POSSÍVEL LOCALIZAR CLIENTE ASAAS PELO CPF"
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

  if (telefoneLimpo) {

    body.mobilePhone =
      telefoneLimpo;
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

async function criarCartao({

  valor,
  email,
  referencia,
  descricao,
  nome,
  cpf,
  telefone,
  usuarioId,

  cartao,

  endereco,

  remoteIp,

}) {

  // ==========================================================
  // VALOR
  // ==========================================================

  const valorNumerico =
    Number(valor);

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
  // CARTÃO
  // ==========================================================

  if (!cartao) {

    throw new Error(
      "Dados do cartão não informados."
    );
  }

  const numero =
    String(
      cartao.numero || ""
    )
      .replace(/\D/g, "");

  const nomeCartao =
    String(
      cartao.nome || ""
    ).trim();

  const mesExpiracao =
    String(
      cartao.mesExpiracao || ""
    )
      .replace(/\D/g, "")
      .padStart(2, "0");

  let anoExpiracao =
    String(
      cartao.anoExpiracao || ""
    )
      .replace(/\D/g, "");

  const cvv =
    String(
      cartao.cvv || ""
    )
      .replace(/\D/g, "");

  // ==========================================================
  // VALIDAR NÚMERO
  // ==========================================================

  if (
    numero.length < 13 ||
    numero.length > 19
  ) {

    throw new Error(
      "Número do cartão inválido."
    );
  }

  // ==========================================================
  // VALIDAR TITULAR
  // ==========================================================

  if (!nomeCartao) {

    throw new Error(
      "Nome do titular do cartão não informado."
    );
  }

  // ==========================================================
  // VALIDAR MÊS
  // ==========================================================

  const mesNumero =
    Number(mesExpiracao);

  if (
    !Number.isInteger(
      mesNumero
    ) ||
    mesNumero < 1 ||
    mesNumero > 12
  ) {

    throw new Error(
      "Mês de validade do cartão inválido."
    );
  }

  // ==========================================================
  // CORRIGIR ANO
  // ==========================================================

  if (
    anoExpiracao.length === 2
  ) {

    anoExpiracao =
      `20${anoExpiracao}`;
  }

  if (
    !/^\d{4}$/.test(
      anoExpiracao
    )
  ) {

    throw new Error(
      "Ano de validade do cartão inválido."
    );
  }

  // ==========================================================
  // VALIDAR CVV
  // ==========================================================

  if (
    cvv.length < 3 ||
    cvv.length > 4
  ) {

    throw new Error(
      "CVV do cartão inválido."
    );
  }

  // ==========================================================
  // CPF
  // ==========================================================

  const documento =
    String(cpf || "")
      .replace(/\D/g, "");

  if (!documento) {

    throw new Error(
      "CPF não cadastrado."
    );
  }

  // ==========================================================
  // TELEFONE
  // ==========================================================

  const telefoneLimpo =
    limparTelefone(telefone);

  if (
    telefoneLimpo.length < 10 ||
    telefoneLimpo.length > 11
  ) {

    throw new Error(
      "Número de contato com DDD do titular do cartão é obrigatório."
    );
  }

  // ==========================================================
  // ENDEREÇO
  // ==========================================================

  const enderecoSeguro =
    endereco || {};

  const cep =
    limparCep(
      enderecoSeguro.cep ||
      enderecoSeguro.CEP ||
      enderecoSeguro.codigoPostal ||
      enderecoSeguro.postalCode ||
      enderecoSeguro.cepCodigo ||
      ""
    );

  const numeroEndereco =
    String(
      enderecoSeguro.numero ||
      enderecoSeguro.numeroEndereco ||
      enderecoSeguro.number ||
      enderecoSeguro.addressNumber ||
      ""
    ).trim();

  const complemento =
    String(
      enderecoSeguro.complemento ||
      enderecoSeguro.complement ||
      enderecoSeguro.addressComplement ||
      ""
    ).trim();

  if (
    cep.length !== 8
  ) {

    throw new Error(
      "CEP do titular do cartão é obrigatório."
    );
  }

  if (!numeroEndereco) {

    throw new Error(
      "Número do endereço é obrigatório para pagamento com cartão."
    );
  }

  // ==========================================================
  // IP DO CLIENTE
  // ==========================================================

  const ipCliente =
    String(
      remoteIp || ""
    ).trim();

  if (!ipCliente) {

    throw new Error(
      "Não foi possível identificar o IP do cliente."
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

      cpf:
        documento,

      telefone:
        telefoneLimpo,

      usuarioId,
    });

  // ==========================================================
  // DADOS DO TITULAR
  // ==========================================================

  const creditCardHolderInfo = {

    name:
      String(nome).trim(),

    email:
      String(email)
        .trim()
        .toLowerCase(),

    cpfCnpj:
      documento,

    postalCode:
      cep,

    addressNumber:
      numeroEndereco,

    phone:
      telefoneLimpo,

    mobilePhone:
      telefoneLimpo,
  };

  if (complemento) {

    creditCardHolderInfo.addressComplement =
      complemento;
  }

  // ==========================================================
  // COBRANÇA ASAAS
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

    // ========================================================
    // CARTÃO
    // ========================================================

    creditCard: {

      holderName:
        nomeCartao,

      number:
        numero,

      expiryMonth:
        mesExpiracao,

      expiryYear:
        anoExpiracao,

      ccv:
        cvv,
    },

    // ========================================================
    // TITULAR
    // ========================================================

    creditCardHolderInfo,

    // ========================================================
    // IP DO COMPRADOR
    // ========================================================

    remoteIp:
      ipCliente,
  };

  try {

    console.log("");
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
      "PEDIDO:",
      referencia
    );

    console.log(
      "VALOR:",
      body.value
    );

    console.log(
      "CEP TITULAR:",
      cep
    );

    console.log(
      "NÚMERO ENDEREÇO:",
      numeroEndereco
    );

    console.log(
      "TELEFONE:",
      telefoneLimpo
    );

    console.log(
      "VALIDADE:",
      `${mesExpiracao}/${anoExpiracao}`
    );

    console.log(
      "IP CLIENTE:",
      ipCliente
    );

    console.log(
      "========================================"
    );

    // ========================================================
    // ENVIAR AO ASAAS
    // ========================================================

    const response =
      await api.post(
        "/v3/payments",
        body
      );

    // ========================================================
    // RESPOSTA
    // ========================================================

    console.log("");
    console.log(
      "========================================"
    );

    console.log(
      "✅ CARTÃO ENVIADO AO ASAAS"
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
      "BANDEIRA:",
      response.data?.creditCard?.creditCardBrand ||
      "NÃO INFORMADA"
    );

    console.log(
      "========================================"
    );

    return response.data;

  } catch (erro) {

    console.error("");
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO CRIANDO CARTÃO ASAAS"
    );

    console.error(
      "STATUS HTTP:",
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

    console.error(
      "========================================"
    );

    throw erro;
  }
}

// ============================================================
// CRIAR COBRANÇA - CARTÃO DE DÉBITO
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

  const valorNumerico =
    Number(valor);

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
// ESTORNAR PAGAMENTO
// ============================================================

async function estornarPagamento(pagamentoId, valor = null) {
    try {
        if (!pagamentoId) {
            throw new Error("ID do pagamento Asaas não informado.");
        }

        console.log("========================================");
        console.log("💸 FOODJET - ESTORNO ASAAS");
        console.log("========================================");
        console.log("🆔 PAGAMENTO ASAAS:", pagamentoId);

        const body = {};

        // Se valor for informado, faz estorno parcial.
        // Se não informar, o Asaas faz estorno total.
        if (valor !== null && valor !== undefined) {
            const valorNumerico = Number(valor);

            if (!Number.isFinite(valorNumerico) || valorNumerico <= 0) {
                throw new Error("Valor de estorno inválido.");
            }

            body.value = Number(valorNumerico.toFixed(2));

            console.log("💰 VALOR DO ESTORNO:", body.value);
        } else {
            console.log("💰 ESTORNO: TOTAL");
        }

        const response = await api.post(
            `/v3/payments/${encodeURIComponent(pagamentoId)}/refund`,
            body
        );

        console.log("✅ ESTORNO SOLICITADO COM SUCESSO");
        console.log("🆔 PAGAMENTO:", pagamentoId);

        if (response.data?.status) {
            console.log(
                "📊 STATUS:",
                response.data.status
            );
        }

        console.log("========================================");

        return response.data;

    } catch (error) {

        console.error("========================================");
        console.error("❌ ERRO AO ESTORNAR PAGAMENTO ASAAS");
        console.error("========================================");

        console.error(
            "🆔 PAGAMENTO:",
            pagamentoId
        );

        console.error(
            "📊 STATUS HTTP:",
            error.response?.status
        );

        console.error(
            "📄 RESPOSTA ASAAS:",
            error.response?.data || error.message
        );

        console.error("========================================");

        throw new Error(
            error.response?.data?.errors?.[0]?.description ||
            error.response?.data?.message ||
            error.message ||
            "Não foi possível estornar o pagamento."
        );
    }
}

module.exports = {
    criarPix,
    criarCartao,
    criarDebito,
    obterQrCodePix,
    consultarPagamento,
    estornarPagamento,
};



