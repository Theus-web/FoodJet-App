require("dotenv").config({ override: true });

const mercadopago = require("mercadopago");

const token = process.env.MERCADOPAGO_ACCESS_TOKEN?.trim();

console.log("========================================");
console.log("🧪 FOODJET - TESTE PIX MERCADO PAGO");
console.log("========================================");
console.log("TOKEN CARREGADO:", !!token);
console.log("PREFIXO:", token?.substring(0, 12));
console.log("TAMANHO:", token?.length);
console.log("========================================");

if (!token) {
  console.error("❌ TOKEN NÃO CARREGADO");
  process.exit(1);
}

const client = new mercadopago.MercadoPagoConfig({
  accessToken: token,
});

const payment = new mercadopago.Payment(client);

async function testar() {
  try {
    console.log("💳 Criando pagamento PIX...");
    console.log("💰 Valor: R$ 10,00");
    console.log(
      "📧 Pagador: test_user_4575768576989414454@testuser.com"
    );

    const resposta = await payment.create({
      body: {
        transaction_amount: 10,
        description: "FoodJet Teste PIX",
        payment_method_id: "pix",
        payer: {
          email: "test_user_4575768576989414454@testuser.com",
        },
        external_reference: "TESTE-FOODJET-001",
      },
    });

    console.log("========================================");
    console.log("✅ PIX CRIADO COM SUCESSO!");
    console.log("========================================");
    console.log("🆔 ID:", resposta.id);
    console.log("📊 STATUS:", resposta.status);
    console.log(
      "📋 DETALHE:",
      resposta.status_detail
    );

    const dadosPix =
      resposta.point_of_interaction?.transaction_data;

    console.log(
      "🔑 QR CODE:",
      dadosPix?.qr_code || "não retornado"
    );

    console.log(
      "🔗 TICKET URL:",
      dadosPix?.ticket_url || "não retornado"
    );

    console.log("========================================");

  } catch (erro) {
    console.log("========================================");
    console.log("❌ ERRO MERCADO PAGO");
    console.log("========================================");
    console.log("STATUS:", erro?.status);
    console.log("ERRO:", erro?.error);
    console.log("MENSAGEM:", erro?.message);
    console.log("CAUSAS:", erro?.causes);
    console.log("========================================");
  }
}

testar();