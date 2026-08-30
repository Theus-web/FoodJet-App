const express = require("express");

const router = express.Router();

const {
  criarCliente,
  criarCobrancaPix,
  obterQrCodePix,
  consultarCobranca,
  cancelarCobranca,
  estornarCobranca,
} = require("../services/asaas_service");

// ==========================================================
// CRIAR PIX
// ==========================================================

router.post(
  "/pagamentos/pix",
  async (req, res) => {

    try {

      console.log("");
      console.log("========================================");
      console.log("💳 FOODJET - CRIAR PIX ASAAS");
      console.log("========================================");

      // ======================================================
      // DADOS RECEBIDOS DO CHECKOUT
      // ======================================================

      const {
        customer,
        nome,
        cpfCnpj,
        email,
        value,
        description,
        pedidoId,
        externalReference,
        dueDate,
        splits,
      } = req.body;

      console.log("👤 NOME:", nome || "não informado");
      console.log("📧 EMAIL:", email || "não informado");
      console.log(
        "🪪 CPF/CNPJ:",
        cpfCnpj ? "INFORMADO" : "NÃO INFORMADO"
      );

      console.log("💰 VALOR:", value);
      console.log("📦 PEDIDO ID:", pedidoId || "não informado");
      console.log(
        "🔖 REFERÊNCIA:",
        externalReference || "não informada"
      );

      // ======================================================
      // VALIDAR VALOR
      // ======================================================

      if (
        value === undefined ||
        value === null ||
        Number(value) <= 0
      ) {

        return res
          .status(400)
          .json({
            success: false,
            error: "value inválido.",
          });

      }

      // ======================================================
      // VALIDAR CPF/CNPJ
      //
      // Se customer já for enviado, podemos usar o cliente
      // existente.
      //
      // Caso contrário, CPF/CNPJ é obrigatório para criar
      // o cliente no Asaas.
      // ======================================================

      let customerId = customer;

      if (!customerId) {

        if (!cpfCnpj) {

          return res
            .status(400)
            .json({
              success: false,

              error:
                "CPF ou CNPJ é obrigatório para criar o pagamento.",

            });

        }

        if (!email) {

          return res
            .status(400)
            .json({
              success: false,

              error:
                "E-mail é obrigatório para criar o cliente Asaas.",

            });

        }

        // ====================================================
        // CRIAR CLIENTE ASAAS
        // ====================================================

        console.log(
          "👤 Criando cliente no Asaas..."
        );

        const cliente =
          await criarCliente({
            name:
              nome ||
              "Cliente FoodJet",

            cpfCnpj:
              cpfCnpj,

            email:
              email,

          });

        customerId =
          cliente.id;

        console.log(
          "✅ CLIENTE ASAAS CRIADO:",
          customerId
        );

      }

      // ======================================================
      // REFERÊNCIA
      // ======================================================

      const referencia =
        externalReference ||
        (
          pedidoId
            ? `FOODJET-${pedidoId}`
            : `FOODJET-${Date.now()}`
        );

      // ======================================================
      // CRIAR COBRANÇA
      // ======================================================

      console.log(
        "💳 Criando cobrança PIX..."
      );

      const cobranca =
        await criarCobrancaPix({

          customer:
            customerId,

          value:
            Number(value),

          description:
            description ||
            "Pedido FoodJet",

          externalReference:
            referencia,

          dueDate,

          splits,

        });

      console.log(
        "========================================"
      );

      console.log(
        "✅ COBRANÇA ASAAS CRIADA"
      );

      console.log(
        "🆔 PAYMENT ID:",
        cobranca.id
      );

      console.log(
        "📊 STATUS:",
        cobranca.status
      );

      console.log(
        "💰 VALOR:",
        cobranca.value
      );

      console.log(
        "🔖 REFERÊNCIA:",
        cobranca.externalReference
      );

      console.log(
        "========================================"
      );

      // ======================================================
      // OBTER QR CODE PIX
      // ======================================================

      console.log(
        "🔎 Obtendo QR Code PIX..."
      );

      const qrCode =
        await obterQrCodePix(
          cobranca.id
        );

      console.log(
        "✅ QR CODE PIX OBTIDO"
      );

      // ======================================================
      // RESPOSTA
      // ======================================================

      return res.json({

        success: true,

        customerId:
          customerId,

        paymentId:
          cobranca.id,

        pedidoId:
          pedidoId ||
          null,

        externalReference:
          referencia,

        payment:
          cobranca,

        pix:
          qrCode,

      });

    } catch (error) {

      console.error("");
      console.error(
        "========================================"
      );

      console.error(
        "❌ ERRO AO CRIAR PIX ASAAS"
      );

      console.error(
        "========================================"
      );

      console.error(
        "STATUS:",
        error.response?.status
      );

      console.error(
        "ASAAS:",
        error.response?.data
      );

      console.error(
        "MENSAGEM:",
        error.message
      );

      console.error(
        "========================================"
      );

      return res
        .status(
          error.response?.status ||
          500
        )
        .json({

          success: false,

          error:
            error.response?.data ||
            error.message,

        });

    }

  }
);

// ==========================================================
// CONSULTAR PAGAMENTO
// ==========================================================

router.get(
  "/pagamentos/:id",
  async (req, res) => {

    try {

      console.log("");
      console.log(
        "========================================"
      );

      console.log(
        "🔎 FOODJET - CONSULTAR PAGAMENTO ASAAS"
      );

      console.log(
        "🆔 PAYMENT ID:",
        req.params.id
      );

      console.log(
        "========================================"
      );

      const pagamento =
        await consultarCobranca(
          req.params.id
        );

      console.log(
        "========================================"
      );

      console.log(
        "✅ PAGAMENTO ASAAS CONSULTADO"
      );

      console.log(
        "========================================"
      );

      console.log(
        "🆔 PAYMENT ID:",
        pagamento.id
      );

      console.log(
        "📊 STATUS:",
        pagamento.status
      );

      console.log(
        "💰 VALOR:",
        pagamento.value
      );

      console.log(
        "🔖 REFERÊNCIA:",
        pagamento.externalReference
      );

      console.log(
        "========================================"
      );

      return res.json({

        success: true,

        payment:
          pagamento,

      });

    } catch (error) {

      console.error(
        "❌ ERRO AO CONSULTAR PAGAMENTO ASAAS:",
        error.response?.data ||
        error.message
      );

      return res
        .status(
          error.response?.status ||
          500
        )
        .json({

          success: false,

          error:
            error.response?.data ||
            error.message,

        });

    }

  }
);

// ==========================================================
// CANCELAR PAGAMENTO
// ==========================================================

router.delete(
  "/pagamentos/:id",
  async (req, res) => {

    try {

      const resultado =
        await cancelarCobranca(
          req.params.id
        );

      return res.json({

        success: true,

        payment:
          resultado,

      });

    } catch (error) {

      console.error(
        "❌ ERRO AO CANCELAR PAGAMENTO ASAAS:",
        error.response?.data ||
        error.message
      );

      return res
        .status(
          error.response?.status ||
          500
        )
        .json({

          success: false,

          error:
            error.response?.data ||
            error.message,

        });

    }

  }
);

// ==========================================================
// ESTORNAR PAGAMENTO
// ==========================================================

router.post(
  "/pagamentos/:id/refund",
  async (req, res) => {

    try {

      const resultado =
        await estornarCobranca(
          req.params.id,
          req.body?.value
        );

      return res.json({

        success: true,

        refund:
          resultado,

      });

    } catch (error) {

      console.error(
        "❌ ERRO AO ESTORNAR PAGAMENTO ASAAS:",
        error.response?.data ||
        error.message
      );

      return res
        .status(
          error.response?.status ||
          500
        )
        .json({

          success: false,

          error:
            error.response?.data ||
            error.message,

        });

    }

  }
);

// ==========================================================
// EXPORTAR
// ==========================================================

module.exports = router;