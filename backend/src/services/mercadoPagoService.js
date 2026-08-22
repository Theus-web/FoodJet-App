const mercadopago = require("mercadopago");

const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN;

if (!accessToken) {
  console.warn(
    "⚠️ MERCADOPAGO_ACCESS_TOKEN não configurado."
  );
}

const client = new mercadopago.MercadoPagoConfig({
  accessToken,
});

const paymentClient = new mercadopago.Payment(client);

async function criarPix({
  valor,
  email,
  descricao,
  pedidoId,
}) {
  if (!valor || Number(valor) <= 0) {
    throw new Error("Valor do pagamento inválido.");
  }

  if (!email) {
    throw new Error("E-mail do cliente obrigatório.");
  }

  const idempotencyKey =
    `foodjet-pix-${pedidoId}-${Date.now()}`;

  const pagamento = await paymentClient.create({
    body: {
      transaction_amount: Number(valor),
      description:
        descricao || `Pedido FoodJet #${pedidoId}`,
      payment_method_id: "pix",
      external_reference: String(pedidoId),

      payer: {
        email,
      },
    },

    requestOptions: {
      idempotencyKey,
    },
  });

  return pagamento;
}

async function consultarPagamento(paymentId) {
  const pagamento =
    await paymentClient.get({
      id: paymentId,
    });

  return pagamento;
}

module.exports = {
  criarPix,
  consultarPagamento,
};