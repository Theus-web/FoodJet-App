// ==========================================================
// ASAAS SERVICE - FOODJET
// ==========================================================

const axios = require("axios");

const ASAAS_API_URL =
  process.env.ASAAS_API_URL ||
  "https://api.asaas.com/v3";

const ASAAS_API_KEY =
  process.env.ASAAS_API_KEY;

if (!ASAAS_API_KEY) {
  console.warn(
    "⚠️ ASAAS_API_KEY NÃO CONFIGURADA"
  );
}

const api = axios.create({
  baseURL: ASAAS_API_URL,

  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
    access_token: ASAAS_API_KEY,
  },

  timeout: 30000,
});

// ==========================================================
// CRIAR CLIENTE
// ==========================================================

async function criarCliente({
  name,
  email,
  cpfCnpj,
  phone,
}) {
  const response = await api.post(
    "/customers",
    {
      name,
      email,
      cpfCnpj,
      phone,
    }
  );

  return response.data;
}

// ==========================================================
// BUSCAR CLIENTE
// ==========================================================

async function buscarCliente(customerId) {
  const response = await api.get(
    `/customers/${customerId}`
  );

  return response.data;
}

// ==========================================================
// CRIAR COBRANÇA PIX
// ==========================================================

async function criarCobrancaPix({
  customer,
  value,
  description,
  externalReference,
  dueDate,
  splits,
}) {
  const payload = {
    customer,

    billingType: "PIX",

    value: Number(value),

    description:
      description ||
      "Pedido FoodJet",

    externalReference:
      externalReference || undefined,

    dueDate:
      dueDate ||
      new Date()
        .toISOString()
        .slice(0, 10),

  };

  if (
    Array.isArray(splits) &&
    splits.length > 0
  ) {
    payload.split = splits;
  }

  const response = await api.post(
    "/payments",
    payload
  );

  return response.data;
}

// ==========================================================
// QR CODE PIX
// ==========================================================

async function obterQrCodePix(paymentId) {
  const response = await api.get(
    `/payments/${paymentId}/pixQrCode`
  );

  return response.data;
}

// ==========================================================
// CONSULTAR COBRANÇA
// ==========================================================

async function consultarCobranca(paymentId) {
  const response = await api.get(
    `/payments/${paymentId}`
  );

  return response.data;
}

// ==========================================================
// CANCELAR COBRANÇA
// ==========================================================

async function cancelarCobranca(paymentId) {
  const response = await api.delete(
    `/payments/${paymentId}`
  );

  return response.data;
}

// ==========================================================
// ESTORNAR COBRANÇA
// ==========================================================

async function estornarCobranca(
  paymentId,
  value = null
) {
  const body = {};

  if (value !== null) {
    body.value = Number(value);
  }

  const response = await api.post(
    `/payments/${paymentId}/refund`,
    body
  );

  return response.data;
}

// ==========================================================
// EXPORT
// ==========================================================

module.exports = {
  criarCliente,
  buscarCliente,
  criarCobrancaPix,
  obterQrCodePix,
  consultarCobranca,
  cancelarCobranca,
  estornarCobranca,
};