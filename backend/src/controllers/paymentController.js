const {
  criarPix,
  consultarPagamento,
} = require("../services/mercadoPagoService");

async function gerarPix(req, res) {
  try {
    const {
      valor,
      email,
      pedidoId,
    } = req.body;

    if (!valor) {
      return res.status(400).json({
        erro: "Valor obrigatório.",
      });
    }

    if (!email) {
      return res.status(400).json({
        erro: "E-mail obrigatório.",
      });
    }

    if (!pedidoId) {
      return res.status(400).json({
        erro: "Pedido obrigatório.",
      });
    }

    const pagamento = await criarPix({
      valor,
      email,
      pedidoId,
      descricao:
        `Pedido FoodJet #${pedidoId}`,
    });

    const transacao =
      pagamento.point_of_interaction
        ?.transaction_data;

    return res.status(201).json({
      sucesso: true,

      pagamentoId: pagamento.id,

      status: pagamento.status,

      statusDetalhe:
        pagamento.status_detail,

      pix: {
        qrCode:
          transacao?.qr_code || "",

        qrCodeBase64:
          transacao?.qr_code_base64 || "",

        ticketUrl:
          transacao?.ticket_url || "",
      },
    });

  } catch (erro) {
    console.error(
      "❌ ERRO MERCADO PAGO PIX:",
      erro
    );

    return res.status(500).json({
      sucesso: false,
      erro:
        erro.message ||
        "Não foi possível gerar o pagamento.",
    });
  }
}

async function consultar(req, res) {
  try {
    const { pagamentoId } = req.params;

    if (!pagamentoId) {
      return res.status(400).json({
        erro: "ID do pagamento obrigatório.",
      });
    }

    const pagamento =
      await consultarPagamento(
        pagamentoId
      );

    return res.json({
      sucesso: true,
      pagamentoId: pagamento.id,
      status: pagamento.status,
      statusDetalhe:
        pagamento.status_detail,
    });

  } catch (erro) {
    console.error(
      "❌ ERRO CONSULTANDO PAGAMENTO:",
      erro
    );

    return res.status(500).json({
      sucesso: false,
      erro:
        erro.message ||
        "Erro ao consultar pagamento.",
    });
  }
}

module.exports = {
  gerarPix,
  consultar,
};