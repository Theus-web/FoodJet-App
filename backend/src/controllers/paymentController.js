const {
  criarPix,
  criarCredito,
  criarDebito,
  consultarPagamento,
  obterQrCodePix,
} = require("../services/asaasService");

// ============================================================
// PIX
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

    if (
      valor === undefined ||
      valor === null ||
      !Number.isFinite(Number(valor)) ||
      Number(valor) <= 0
    ) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Valor do pagamento obrigatório.",
      });
    }

    if (!email) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "E-mail da conta não encontrado.",
      });
    }

    if (!pedidoId) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "ID do pedido obrigatório.",
      });
    }

    const pagamento =
      await criarPix({
        valor:
          Number(valor),

        email:
          String(email)
            .trim()
            .toLowerCase(),

        pedidoId,

        referencia:
          String(pedidoId).trim(),

        nome,

        cpfCnpj,

        descricao:
          `Pedido FoodJet #${pedidoId}`,
      });

    const pagamentoId =
      pagamento?.id;

    if (!pagamentoId) {
      throw new Error(
        "O Asaas não retornou o ID da cobrança."
      );
    }

    let pix = null;

    try {
      pix =
        await obterQrCodePix(
          pagamentoId
        );
    } catch (erro) {
      console.error(
        "⚠️ Não foi possível obter QR Code PIX:",
        erro?.message
      );
    }

    return res.status(201).json({
      sucesso: true,

      pagamentoId,

      paymentId:
        pagamentoId,

      status:
        pagamento?.status || "",

      externalReference:
        pagamento?.externalReference ||
        String(pedidoId),

      totalAmount:
        pagamento?.value ||
        Number(valor),

      billingType:
        "PIX",

      pix: {
        qrCode:
          pix?.payload || "",

        qrCodeBase64:
          pix?.encodedImage || "",

        ticketUrl:
          "",

        expiracao:
          pix?.expirationDate || "",
      },
    });
  } catch (erro) {
    console.error(
      "❌ ERRO GERANDO PIX:",
      erro?.message
    );

    return res.status(
      erro?.response?.status >= 400 &&
      erro?.response?.status < 600
        ? erro.response.status
        : 500
    ).json({
      sucesso: false,

      erro:
        erro?.response?.data?.errors?.[0]
          ?.description ||
        erro?.message ||
        "Não foi possível gerar o PIX.",
    });
  }
}

// ============================================================
// CRÉDITO
// ============================================================

async function gerarCredito(req, res) {
  try {
    const {
      valor,
      email,
      pedidoId,
      nome,
      cpfCnpj,
      creditCard,
      creditCardHolderInfo,
      installmentCount,
    } = req.body;

    if (
      !Number.isFinite(Number(valor)) ||
      Number(valor) <= 0
    ) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Valor inválido.",
      });
    }

    if (!email) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "E-mail obrigatório.",
      });
    }

    if (!pedidoId) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Pedido obrigatório.",
      });
    }

    const remoteIp =
      req.headers["x-forwarded-for"]
        ?.split(",")[0]
        ?.trim() ||
      req.socket?.remoteAddress;

    const pagamento =
      await criarCredito({
        valor:
          Number(valor),

        email,

        referencia:
          String(pedidoId),

        nome,

        cpfCnpj,

        creditCard,

        creditCardHolderInfo,

        remoteIp,

        installmentCount,
      });

    return res.status(200).json({
      sucesso: true,

      pagamentoId:
        pagamento?.id,

      paymentId:
        pagamento?.id,

      status:
        pagamento?.status,

      statusDetalhe:
        pagamento?.status,

      totalAmount:
        pagamento?.value ||
        Number(valor),

      externalReference:
        pagamento?.externalReference ||
        String(pedidoId),

      billingType:
        "CREDIT_CARD",

      invoiceUrl:
        pagamento?.invoiceUrl || "",
    });
  } catch (erro) {
    console.error(
      "❌ ERRO CARTÃO DE CRÉDITO:",
      erro?.message
    );

    return res.status(
      erro?.response?.status >= 400 &&
      erro?.response?.status < 600
        ? erro.response.status
        : 500
    ).json({
      sucesso: false,

      erro:
        erro?.response?.data?.errors?.[0]
          ?.description ||
        erro?.message ||
        "Não foi possível processar o cartão.",
    });
  }
}

// ============================================================
// DÉBITO
// ============================================================

async function gerarDebito(req, res) {
  try {
    const {
      valor,
      email,
      pedidoId,
      nome,
      cpfCnpj,
    } = req.body;

    if (
      !Number.isFinite(Number(valor)) ||
      Number(valor) <= 0
    ) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Valor inválido.",
      });
    }

    if (!email) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "E-mail obrigatório.",
      });
    }

    if (!pedidoId) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Pedido obrigatório.",
      });
    }

    const pagamento =
      await criarDebito({
        valor:
          Number(valor),

        email,

        referencia:
          String(pedidoId),

        nome,

        cpfCnpj,

        descricao:
          `Pedido FoodJet #${pedidoId}`,
      });

    return res.status(201).json({
      sucesso: true,

      pagamentoId:
        pagamento?.id,

      paymentId:
        pagamento?.id,

      status:
        pagamento?.status,

      billingType:
        "CREDIT_CARD",

      invoiceUrl:
        pagamento?.invoiceUrl || "",

      externalReference:
        pagamento?.externalReference ||
        String(pedidoId),

      mensagem:
        "Continue o pagamento pela página segura do Asaas.",
    });
  } catch (erro) {
    console.error(
      "❌ ERRO CARTÃO DE DÉBITO:",
      erro?.message
    );

    return res.status(
      erro?.response?.status >= 400 &&
      erro?.response?.status < 600
        ? erro.response.status
        : 500
    ).json({
      sucesso: false,

      erro:
        erro?.response?.data?.errors?.[0]
          ?.description ||
        erro?.message ||
        "Não foi possível iniciar o pagamento com débito.",
    });
  }
}

// ============================================================
// DINHEIRO
// ============================================================

async function registrarDinheiro(
  req,
  res
) {
  try {
    const {
      valor,
      pedidoId,
    } = req.body;

    if (
      !Number.isFinite(Number(valor)) ||
      Number(valor) <= 0
    ) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Valor inválido.",
      });
    }

    if (!pedidoId) {
      return res.status(400).json({
        sucesso: false,
        erro:
          "Pedido obrigatório.",
      });
    }

    return res.status(200).json({
      sucesso: true,

      pagamentoId:
        null,

      paymentId:
        null,

      status:
        "PENDING",

      statusDetalhe:
        "PENDING",

      billingType:
        "CASH",

      totalAmount:
        Number(valor),

      externalReference:
        String(pedidoId),

      mensagem:
        "Pagamento será realizado na entrega.",
    });
  } catch (erro) {
    console.error(
      "❌ ERRO PAGAMENTO DINHEIRO:",
      erro?.message
    );

    return res.status(500).json({
      sucesso: false,
      erro:
        "Não foi possível registrar o pagamento em dinheiro.",
    });
  }
}

// ============================================================
// CONSULTAR
// ============================================================

async function consultar(req, res) {
  try {
    const {
      pagamentoId,
    } = req.params;

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

    const pagamento =
      await consultarPagamento(
        pagamentoId
      );

    return res.json({
      sucesso: true,

      pagamentoId:
        pagamento?.id ||
        pagamentoId,

      orderId:
        pagamento?.id ||
        pagamentoId,

      paymentId:
        pagamento?.id ||
        pagamentoId,

      status:
        pagamento?.status || "",

      statusDetalhe:
        pagamento?.status || "",

      totalAmount:
        pagamento?.value,

      externalReference:
        pagamento?.externalReference,

      billingType:
        pagamento?.billingType || "",

      invoiceUrl:
        pagamento?.invoiceUrl || "",

      pix: {
        qrCode: "",
        qrCodeBase64: "",
        ticketUrl: "",
        expiracao:
          pagamento?.dueDate || "",
      },
    });
  } catch (erro) {
    console.error(
      "❌ ERRO CONSULTANDO PAGAMENTO:",
      erro?.message
    );

    return res.status(
      erro?.response?.status >= 400 &&
      erro?.response?.status < 600
        ? erro.response.status
        : 500
    ).json({
      sucesso: false,

      erro:
        erro?.response?.data?.errors?.[0]
          ?.description ||
        erro?.message ||
        "Erro ao consultar pagamento.",
    });
  }
}

module.exports = {
  gerarPix,
  gerarCredito,
  gerarDebito,
  registrarDinheiro,
  consultar,
};