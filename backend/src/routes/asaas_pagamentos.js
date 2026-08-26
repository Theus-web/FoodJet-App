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

      const {
        customer,
        value,
        description,
        externalReference,
        dueDate,
        splits,
      } = req.body;

      if (!customer) {

        return res
          .status(400)
          .json({
            error:
              "customer é obrigatório",
          });
      }

      if (
        !value ||
        Number(value) <= 0
      ) {

        return res
          .status(400)
          .json({
            error:
              "value inválido",
          });
      }

      const cobranca =
        await criarCobrancaPix({
          customer,
          value,
          description,
          externalReference,
          dueDate,
          splits,
        });

      const qrCode =
        await obterQrCodePix(
          cobranca.id
        );

      return res.json({
        success: true,

        payment: cobranca,

        pix: qrCode,
      });

    } catch (error) {

      console.error(
        "❌ ERRO AO CRIAR PIX ASAAS:",
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
// CONSULTAR
// ==========================================================

router.get(
  "/pagamentos/:id",
  async (req, res) => {

    try {

      const pagamento =
        await consultarCobranca(
          req.params.id
        );

      return res.json({
        success: true,
        payment: pagamento,
      });

    } catch (error) {

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
// CANCELAR
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
        payment: resultado,
      });

    } catch (error) {

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
// ESTORNAR
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
        refund: resultado,
      });

    } catch (error) {

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

module.exports = router;