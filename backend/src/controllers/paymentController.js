const {
  criarPix,
  consultarPagamento,
  obterQrCodePix,
} = require("../services/asaasService");

// ============================================================
// GERAR PIX ASAAS
// ============================================================

async function gerarPix(req, res) {
  try {
    const {
      valor,
      email,
      pedidoId,
      nome,
      cpfCnpj,
    } = req.body;

    console.log("========================================");
    console.log("💳 FOODJET - GERAR PIX ASAAS");
    console.log("========================================");
    console.log("💰 VALOR:", valor);
    console.log("📧 EMAIL:", email);
    console.log("🔖 PEDIDO:", pedidoId);
    console.log("👤 USUÁRIO:", req.usuario?.id);
    console.log("========================================");

    // ========================================================
    // VALIDAR VALOR
    // ========================================================

    if (
      valor === undefined ||
      valor === null ||
      !Number.isFinite(Number(valor)) ||
      Number(valor) <= 0
    ) {
      return res.status(400).json({
        sucesso: false,
        erro: "Valor do pagamento obrigatório.",
      });
    }

    // ========================================================
    // VALIDAR EMAIL
    // ========================================================

    if (
      !email ||
      typeof email !== "string" ||
      !email.trim()
    ) {
      return res.status(400).json({
        sucesso: false,
        erro: "E-mail da conta não encontrado.",
      });
    }

    const emailNormalizado =
      email.trim().toLowerCase();

    // ========================================================
    // VALIDAR PEDIDO
    // ========================================================

    if (
      !pedidoId ||
      !String(pedidoId).trim()
    ) {
      return res.status(400).json({
        sucesso: false,
        erro: "ID do pedido obrigatório.",
      });
    }

    const referencia =
      String(pedidoId).trim();

    // ========================================================
    // CRIAR COBRANÇA PIX
    // ========================================================

    const pagamento =
      await criarPix({
        valor: Number(valor),
        email: emailNormalizado,
        referencia,
        nome,
        cpfCnpj,
        descricao:
          `Pedido FoodJet #${referencia}`,
      });

    // ========================================================
    // ID ASAAS
    // ========================================================

    const pagamentoId =
      pagamento?.id || "";

    if (!pagamentoId) {
      console.error(
        "❌ Asaas não retornou o ID da cobrança."
      );

      return res.status(502).json({
        sucesso: false,
        erro:
          "O Asaas não retornou o ID da cobrança.",
      });
    }

    console.log("========================================");
    console.log("✅ COBRANÇA ASAAS CRIADA");
    console.log("========================================");
    console.log(
      "🆔 PAYMENT ID:",
      pagamentoId
    );
    console.log(
      "📊 STATUS:",
      pagamento?.status
    );
    console.log(
      "💰 VALOR:",
      pagamento?.value
    );
    console.log(
      "📅 VENCIMENTO:",
      pagamento?.dueDate
    );
    console.log(
      "🔖 REFERÊNCIA:",
      pagamento?.externalReference
    );
    console.log("========================================");

    // ========================================================
    // OBTER QR CODE PIX
    // ========================================================

    let pix = null;

    try {

      pix =
        await obterQrCodePix(
          pagamentoId
        );

    } catch (qrErro) {

      console.error(
        "⚠️ ERRO AO OBTER QR CODE PIX:"
      );

      console.error(
        qrErro?.message
      );

      /*
       * A cobrança já foi criada.
       *
       * Não criamos outra cobrança.
       *
       * O Flutter poderá tentar consultar novamente.
       */

      pix = null;
    }

    // ========================================================
    // RESPOSTA
    // ========================================================

    return res.status(201).json({
      sucesso: true,

      pagamentoId,

      paymentId:
        pagamentoId,

      status:
        pagamento?.status || "",

      statusDetalhe:
        pagamento?.status || "",

      externalReference:
        pagamento?.externalReference ||
        referencia,

      totalAmount:
        pagamento?.value ||
        Number(valor),

      billingType:
        pagamento?.billingType ||
        "PIX",

      pix: {
        qrCode:
          pix?.payload ||
          "",

        qrCodeBase64:
          pix?.encodedImage ||
          "",

        ticketUrl:
          "",

        expiracao:
          pix?.expirationDate ||
          "",
      },
    });

  } catch (erro) {

    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO ASAAS PIX"
    );

    console.error(
      "========================================"
    );

    console.error(
      "STATUS:",
      erro?.status
    );

    console.error(
      "ERRO:",
      erro?.message
    );

    console.error(
      "DETALHES:",
      JSON.stringify(
        erro?.response?.data ||
        erro?.causes ||
        [],
        null,
        2
      )
    );

    console.error(
      "========================================"
    );

    return res.status(
      erro?.status >= 400 &&
      erro?.status < 600
        ? erro.status
        : 500
    ).json({
      sucesso: false,

      erro:
        erro?.message ||
        "Não foi possível iniciar o pagamento PIX.",

      causas:
        erro?.response?.data ||
        erro?.causes ||
        [],
    });
  }
}

// ============================================================
// CONSULTAR PAGAMENTO ASAAS
// ============================================================

async function consultar(req, res) {

  try {

    const {
      pagamentoId,
    } = req.params;

    console.log("========================================");
    console.log(
      "🔎 FOODJET - CONSULTAR PAGAMENTO ASAAS"
    );
    console.log(
      "🆔 PAYMENT ID:",
      pagamentoId
    );
    console.log("========================================");

    // ========================================================
    // VALIDAR ID
    // ========================================================

    if (
      !pagamentoId ||
      !String(pagamentoId).trim()
    ) {

      return res.status(400).json({
        sucesso: false,
        erro:
          "ID do pagamento obrigatório.",
      });

    }

    const id =
      String(pagamentoId).trim();

    // ========================================================
    // CONSULTAR ASAAS
    // ========================================================

    const pagamento =
      await consultarPagamento(id);

    // ========================================================
    // STATUS
    // ========================================================

    const status =
      pagamento?.status || "";

    // ========================================================
    // LOG
    // ========================================================

    console.log("========================================");
    console.log(
      "✅ PAGAMENTO ASAAS CONSULTADO"
    );
    console.log("========================================");

    console.log(
      "🆔 PAYMENT ID:",
      pagamento?.id || id
    );

    console.log(
      "📊 STATUS:",
      status
    );

    console.log(
      "💰 VALOR:",
      pagamento?.value
    );

    console.log(
      "🔖 REFERÊNCIA:",
      pagamento?.externalReference
    );

    console.log("========================================");

    // ========================================================
    // RESPOSTA
    // ========================================================

    return res.json({

      sucesso: true,

      pagamentoId:
        pagamento?.id ||
        id,

      orderId:
        pagamento?.id ||
        id,

      paymentId:
        pagamento?.id ||
        id,

      status,

      statusDetalhe:
        status,

      totalAmount:
        pagamento?.value,

      externalReference:
        pagamento?.externalReference,

      billingType:
        pagamento?.billingType ||
        "PIX",

      pix: {
        qrCode: "",

        qrCodeBase64: "",

        ticketUrl: "",

        expiracao:
          pagamento?.dueDate ||
          "",
      },

    });

  } catch (erro) {

    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO CONSULTANDO ASAAS"
    );

    console.error(
      "========================================"
    );

    console.error(
      "STATUS:",
      erro?.status
    );

    console.error(
      "ERRO:",
      erro?.message
    );

    console.error(
      "DETALHES:",
      JSON.stringify(
        erro?.response?.data ||
        erro?.causes ||
        [],
        null,
        2
      )
    );

    console.error(
      "========================================"
    );

    return res.status(
      erro?.status >= 400 &&
      erro?.status < 600
        ? erro.status
        : 500
    ).json({

      sucesso: false,

      erro:
        erro?.message ||
        "Erro ao consultar pagamento.",

      causas:
        erro?.response?.data ||
        erro?.causes ||
        [],
    });

  }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
  gerarPix,
  consultar,
};