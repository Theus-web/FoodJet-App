const {
  criarPix,
  consultarOrder,
} = require("../services/mercadoPagoService");

// ============================================================
// GERAR PIX
// ============================================================

async function gerarPix(req, res) {
  try {
    const {
      valor,
      email,
      pedidoId,
    } = req.body;

    console.log("========================================");
    console.log("💳 FOODJET - GERAR PIX");
    console.log("========================================");
    console.log("💰 VALOR:", valor);
    console.log("📧 EMAIL:", email);
    console.log("🔖 REFERÊNCIA:", pedidoId);
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
    // VALIDAR REFERÊNCIA
    // ========================================================

    if (
      !pedidoId ||
      !String(pedidoId).trim()
    ) {
      return res.status(400).json({
        sucesso: false,
        erro: "Referência do pagamento obrigatória.",
      });
    }

    const referencia =
      String(pedidoId).trim();

    // ========================================================
    // CRIAR PIX
    // ========================================================

    const pagamento =
      await criarPix({
        valor: Number(valor),

        email:
          emailNormalizado,

        referencia:
          referencia,

        descricao:
          `Pedido FoodJet #${referencia}`,
      });

    // ========================================================
    // IDs
    // ========================================================

    const orderId =
      pagamento?.order_id ||
      pagamento?.id ||
      "";

    const paymentId =
      pagamento?.payment_id ||
      "";

    console.log("========================================");
    console.log("✅ PAGAMENTO MERCADO PAGO CRIADO");
    console.log("========================================");
    console.log("🆔 ORDER ID:", orderId);
    console.log("🆔 PAYMENT ID:", paymentId);
    console.log("📊 STATUS:", pagamento?.status);
    console.log(
      "📋 STATUS DETALHE:",
      pagamento?.status_detail
    );
    console.log(
      "🔑 QR CODE:",
      pagamento?.qr_code ? "SIM" : "NÃO"
    );
    console.log(
      "🖼️ QR CODE BASE64:",
      pagamento?.qr_code_base64 ? "SIM" : "NÃO"
    );
    console.log(
      "🔗 TICKET URL:",
      pagamento?.ticket_url ? "SIM" : "NÃO"
    );
    console.log("========================================");

    // ========================================================
    // VALIDAR ORDER ID
    // ========================================================

    if (!orderId) {
      console.error(
        "❌ Mercado Pago não retornou ORDER ID."
      );

      return res.status(502).json({
        sucesso: false,
        erro:
          "O Mercado Pago não retornou o ID da Order.",
      });
    }

    // ========================================================
    // VALIDAR PIX
    // ========================================================

    const qrCode =
      pagamento?.qr_code || "";

    const qrCodeBase64 =
      pagamento?.qr_code_base64 || "";

    const ticketUrl =
      pagamento?.ticket_url || "";

    if (
      !qrCode &&
      !qrCodeBase64
    ) {
      console.error(
        "❌ Mercado Pago não retornou QR Code."
      );

      return res.status(502).json({
        sucesso: false,
        erro:
          "O Mercado Pago não retornou os dados do PIX.",
      });
    }

    // ========================================================
    // RESPOSTA PARA O FLUTTER
    // ========================================================
    //
    // ATENÇÃO:
    //
    // pagamentoId = ORDER ID
    //
    // O Flutter utiliza esse ID para:
    //
    // GET /pagamentos/:pagamentoId
    //
    // que depois consulta:
    //
    // GET /v1/orders/:orderId
    //
    // ========================================================

    return res.status(201).json({
      sucesso: true,

      // ORDER ID
      pagamentoId:
        orderId,

      orderId:
        orderId,

      // PAYMENT ID separado
      paymentId:
        paymentId,

      status:
        pagamento?.status,

      statusDetalhe:
        pagamento?.status_detail,

      externalReference:
        pagamento?.external_reference,

      totalAmount:
        pagamento?.total_amount,

      pix: {
        qrCode:
          qrCode,

        qrCodeBase64:
          qrCodeBase64,

        ticketUrl:
          ticketUrl,

        expiracao:
          pagamento?.date_of_expiration || "",
      },
    });

  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO MERCADO PAGO PIX"
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
      "CAUSAS:",
      erro?.causes
    );

    console.error(
      "RESPOSTA:",
      erro?.response
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
        "Não foi possível iniciar o pagamento.",

      causas:
        erro?.causes || [],
    });
  }
}

// ============================================================
// CONSULTAR ORDER
// ============================================================

async function consultar(req, res) {
  try {
    const {
      pagamentoId,
    } = req.params;

    console.log("========================================");
    console.log(
      "🔎 FOODJET - CONSULTAR ORDER"
    );
    console.log(
      "🆔 ORDER ID:",
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
          "ID da Order obrigatório.",
      });
    }

    const orderId =
      String(pagamentoId).trim();

    // ========================================================
    // CONSULTAR MERCADO PAGO
    // ========================================================

    console.log("========================================");
    console.log("🔎 CONSULTANDO ORDER");
    console.log(
      "🆔 ORDER ID:",
      orderId
    );
    console.log("========================================");

    const pagamento =
      await consultarOrder(orderId);

    // ========================================================
    // LOCALIZAR PAYMENT
    // ========================================================

    const payment =
      pagamento
        ?.transactions
        ?.payments
        ?.[
          0
        ] || {};

    // ========================================================
    // STATUS
    // ========================================================

    const status =
      payment?.status ||
      pagamento?.status ||
      "";

    const statusDetalhe =
      payment?.status_detail ||
      pagamento?.status_detail ||
      "";

    // ========================================================
    // LOG
    // ========================================================

    console.log("========================================");
    console.log("✅ ORDER CONSULTADA");
    console.log("========================================");
    console.log(
      "🆔 ORDER ID:",
      pagamento?.id || orderId
    );
    console.log(
      "🆔 PAYMENT ID:",
      payment?.id || ""
    );
    console.log(
      "📊 STATUS:",
      status
    );
    console.log(
      "📋 STATUS DETALHE:",
      statusDetalhe
    );
    console.log("========================================");

    // ========================================================
    // RESPOSTA
    // ========================================================

    return res.json({
      sucesso: true,

      // ORDER
      pagamentoId:
        pagamento?.id ||
        orderId,

      orderId:
        pagamento?.id ||
        orderId,

      // PAYMENT
      paymentId:
        payment?.id || "",

      status:
        status,

      statusDetalhe:
        statusDetalhe,

      totalAmount:
        pagamento?.total_amount,

      externalReference:
        pagamento?.external_reference,

      // PIX
      pix: {
        qrCode:
          payment
            ?.payment_method
            ?.qr_code ||
          "",

        qrCodeBase64:
          payment
            ?.payment_method
            ?.qr_code_base64 ||
          "",

        ticketUrl:
          payment
            ?.payment_method
            ?.ticket_url ||
          "",
      },
    });

  } catch (erro) {
    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO CONSULTANDO ORDER"
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
      "CAUSAS:",
      JSON.stringify(
        erro?.causes || [],
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
        erro?.causes || [],
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